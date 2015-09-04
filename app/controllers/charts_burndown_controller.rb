class ChartsBurndownController < ChartsController

  unloadable

  protected

  def get_data
    total_estimated_hours, total_logged_hours, total_remaining_hours, total_predicted_hours, total_done = get_data_for_burndown_chart

    max = 0
    estimated = []
    logged = []
    remaining = []
    predicted = []

    @range[:keys].each_with_index do |key,index|
      max = total_predicted_hours[index] if max < total_predicted_hours[index]
      max = total_estimated_hours[index] if max < total_estimated_hours[index]
      estimated << [total_estimated_hours[index], t(:charts_burndown_hint_estimated, { :estimated_hours => RedmineCharts::Utils.round(total_estimated_hours[index]) })]
      logged  << [total_logged_hours[index], t(:charts_burndown_hint_logged, { :logged_hours => RedmineCharts::Utils.round(total_logged_hours[index]) })]
      remaining << [total_remaining_hours[index], t(:charts_burndown_hint_remaining, { :remaining_hours => RedmineCharts::Utils.round(total_remaining_hours[index]), :work_done => total_done[index] > 0 ? Integer(total_done[index]) : 0 })]
      if total_predicted_hours[index] > total_estimated_hours[index]
        predicted << [total_predicted_hours[index], t(:charts_burndown_hint_predicted_over_estimation, { :predicted_hours => RedmineCharts::Utils.round(total_predicted_hours[index]), :hours_over_estimation => RedmineCharts::Utils.round(total_predicted_hours[index] - total_estimated_hours[index]) }), true]
      else
        predicted << [total_predicted_hours[index], t(:charts_burndown_hint_predicted, { :predicted_hours => RedmineCharts::Utils.round(total_predicted_hours[index]) })]
      end
    end

    sets = [
      [l(:charts_burndown_group_estimated), estimated],
      [l(:charts_burndown_group_logged), logged],
      [l(:charts_burndown_group_remaining), remaining],
      [l(:charts_burndown_group_predicted), predicted],
    ]

    {
      :labels => @range[:labels],
      :count => @range[:keys].size,
      :max => max > 1 ? max : 1,
      :sets => sets
    }
  end

  def get_data_for_burndown_chart
    conditions = {}

    @conditions.each do |c, v|
      column_name = RedmineCharts::ConditionsUtils.to_column(c, 'issues')
      column_name = 'issues.id' if column_name == 'issues.issue_id' 
      conditions[column_name] = v if v and column_name
    end

    issues = Issue.where(conditions)

    rows, @range = ChartTimeEntry.get_timeline(:issue_id, @conditions, @range)

    current_logged_hours_per_issue = ChartTimeEntry.get_aggregation_for_issue(@conditions, @range)

    done_ratios_per_issue = ChartDoneRatio.get_timeline_for_issue(@conditions, @range)

    total_estimated_hours = Array.new(@range[:keys].size, 0)
    total_logged_hours = Array.new(@range[:keys].size, 0)
    total_remaining_hours = Array.new(@range[:keys].size, 0)
    total_predicted_hours = Array.new(@range[:keys].size, 0)
    total_done = Array.new(@range[:keys].size, 0)
    issues_per_date = Array.new(@range[:keys].size, 0)
    issues_children = []
    logged_hours_per_issue = {}
    estimated_hours_per_issue = {}

    logged_hours_per_issue[0] = Array.new(@range[:keys].size, current_logged_hours_per_issue[0] || 0)
    estimated_hours_per_issue[0] ||= Array.new(@range[:keys].size, 0)

    issues.each do |issue|
      logged_hours_per_issue[issue.id] ||= Array.new(@range[:keys].size, current_logged_hours_per_issue[issue.id] || 0)
      estimated_hours_per_issue[issue.id] ||= Array.new(@range[:keys].size, 0)

      if RedmineCharts.has_sub_issues_functionality_active
        issues_children << issue.parent_id if issue.parent_id
      end

      if @range[:range] == :days
        range_value = issue.created_on.to_time.strftime('%Y%j')
      elsif @range[:range] == :weeks
        range_value = issue.created_on.to_time.strftime('%Y0%W')
      else
        range_value = issue.created_on.to_time.strftime('%Y0%m')
      end
      @range[:keys].each_with_index do |key, i|
        estimated_hours_per_issue[issue.id][i] = issue.estimated_hours if range_value <= key and issue.estimated_hours
        issues_per_date[i] += 1 if range_value <= key
      end
    end

    issues_children.each do |issue_with_children|
      estimated_hours_per_issue[issue_with_children] = Array.new(@range[:keys].size, 0)
    end

    rows.each do |row|
      index = @range[:keys].index(row.range_value.to_s)
      (0..(index-1)).each do |i|
        logged_hours_per_issue[row.group_id.to_i][i] -= row.logged_hours.to_f if logged_hours_per_issue[row.group_id.to_i]
      end
    end

    @range[:keys].each_with_index do |key,index|
      issues.each do |issue|
        logged = logged_hours_per_issue[issue.id] ? logged_hours_per_issue[issue.id][index] : 0
        estimated = estimated_hours_per_issue[issue.id] ? estimated_hours_per_issue[issue.id][index] : 0
        done_ratio = done_ratios_per_issue[issue.id] ? done_ratios_per_issue[issue.id][index] : 0

        total_remaining_hours[index] += ((done_ratio > 0 and logged > 0) ? (logged/done_ratio) : (estimated/100)) * (100-done_ratio)

        total_logged_hours[index] += logged
        total_estimated_hours[index] += estimated
        total_done[index] += done_ratio
      end

      total_logged_hours[index] += logged_hours_per_issue[0][index]

      if issues_per_date[index] > 0
        total_done[index] = total_done[index].to_f / issues_per_date[index]
      else
        total_done[index] = 0
      end

      total_predicted_hours[index] = total_remaining_hours[index] + total_logged_hours[index]

      total_logged_hours[index] = 0 if total_logged_hours[index] < 0.01
      total_estimated_hours[index] = 0 if total_estimated_hours[index] < 0.01
      total_remaining_hours[index] = 0 if total_remaining_hours[index] < 0.01
      total_done[index] = 0 if total_done[index] < 0.01
      total_predicted_hours[index] = 0 if total_predicted_hours[index] < 0.01
    end

    [total_estimated_hours, total_logged_hours, total_remaining_hours, total_predicted_hours, total_done]
  end

  def get_title
    l(:charts_link_burndown)
  end

  def get_help
    l(:charts_burndown_help)
  end

  def get_x_legend
    l(:charts_burndown_x)
  end

  def get_y_legend
    l(:charts_burndown_y)
  end

  def show_date_condition
    true
  end

  def get_multiconditions_options
    (RedmineCharts::ConditionsUtils.types - [:activity_ids, :user_ids]).flatten
  end

end
