namespace :charts do
  task :migrate => :environment do
    ChartDoneRatio.delete_all
    ChartIssueStatus.delete_all
    ChartTimeEntry.delete_all

    Journal.where(:journalized_type => "Issue").order("id asc").each do |journal|
      journal.details.each do |detail|
        if detail.property == "attr"
          if detail.prop_key == "done_ratio"
            RedmineCharts::IssuePatch.add_chart_done_ratio(journal.issue.project_id, journal.issue.id, journal.issue.status_id, detail.value.to_i, journal.created_on)
          elsif detail.prop_key == "status_id"
            RedmineCharts::IssuePatch.add_chart_issue_status(journal.issue.project_id, journal.issue.id, detail.value.to_i, journal.created_on)
          end
        end
      end
    end

    TimeEntry.order("id asc").each do |t|
      RedmineCharts::TimeEntryPatch.add_chart_time_entry(t.project_id, t.issue_id, t.user_id, t.activity_id, t.hours, t.spent_on)
    end
  end
end