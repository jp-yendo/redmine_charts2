module RedmineCharts
  module ConditionsUtils

    include Redmine::I18n
    
    @@types = [ :issue_ids, :project_ids, :user_ids, :category_ids, :status_ids, :activity_ids, :fixed_version_ids, :tracker_ids, :priority_ids, :author_ids, :assigned_to_ids ]

    def self.types
      @@types
    end

    def self.from_params(types, project_id, params)
      conditions = {}
      types.each do |type|
        values = params[type]
        values = [values] unless values.is_a? Array
        values = values.collect { |value| value.blank? ? 0 : Integer(value) }
        values = values.select { |value| value > 0 }
        conditions[type] = values unless values.empty?
      end

      if conditions[:project_ids]
        project_ids = Project.all.collect { |project| project.id } 
        conditions[:project_ids] = conditions[:project_ids].select { |p| project_ids.include? p }
      end

      if conditions[:project_ids].nil? or conditions[:project_ids].empty?
        conditions[:project_ids] = project_and_its_children_ids(project_id)
      end
      conditions
    end

    def self.to_options(project, types)
      conditions = {}
      
      #members = User.all.collect { |a| [a.name, a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase }
      members = project.members.collect { |a| [a.name, a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase }

      types.each do |type|
        case type
          when :user_ids then conditions[:user_ids] = members unless members.size == 0
          when :assigned_to_ids then conditions[:assigned_to_ids] = members unless members.size == 0
          when :author_ids then conditions[:author_ids] = members unless members.size == 0
          when :issue_ids then conditions[:issue_ids] = nil

          when :project_ids then conditions[:project_ids] = Project.all.collect { |a| [a.name, a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase }
          #Gets Current project and sub projects (of current projects) to which user has access. Both arrays are merged using |
          when :project_ids then conditions[:project_ids] = (project.to_a.collect { |a| [a.name, a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase }) | (project.children.visible.all.collect { |a| [a.name, a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase })

          when :activity_ids then conditions[:activity_ids] = TimeEntryActivity.where(["active=?",true]).collect { |a| [a.name, a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase }

          #when :category_ids then conditions[:category_ids] = IssueCategory.all.collect { |a| ["#{a.project.name} - #{a.name}", a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase }
          when :category_ids then
            categories = project.issue_categories.all.collect { |a| ["#{a.project.name} - #{a.name}", a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase }
            conditions[:category_ids] = categories unless categories.size == 0

          #when :fixed_version_ids then conditions[:fixed_version_ids] = Version.all.collect { |a| ["#{a.project.name} - #{a.name}", a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase }
          when :fixed_version_ids then
            versions = project.versions.all.collect { |a| ["#{a.project.name} - #{a.name}", a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase }
            conditions[:fixed_version_ids] = versions unless versions.size == 0

          when :tracker_ids then conditions[:tracker_ids] = Tracker.all.collect { |a| [a.name, a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase }
          when :priority_ids then conditions[:priority_ids] = IssuePriority.all.collect { |a| [a.name, a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase }
          when :status_ids then conditions[:status_ids] = IssueStatus.all.collect { |a| [a.name, a.id] }.sort { |a,b| a[0].upcase <=> b[0].upcase }
        end
      end
      conditions
    end

    def self.to_column(symbol, table)
      case symbol
      when :user_ids then "#{table}.user_id"
      when :author_ids then "issues.author_id"
      when :assigned_to_ids then "issues.assigned_to_id"
      when :issue_ids then "#{table}.issue_id"
      when :activity_ids then "#{table}.activity_id"
      when :category_ids then "issues.category_id"
      when :priority_ids then "issues.priority_id"
      when :tracker_ids then "issues.tracker_id"
      when :fixed_version_ids then "issues.fixed_version_id"
      when :project_ids then "#{table}.project_id"
      when :status_ids then "issues.status_id"
      when :months then "#{table}.month"
      when :weeks then "#{table}.week"
      when :days then "#{table}.day"
      end
    end
    
    private 

    def self.project_and_its_children_ids(project_id)
      project_ids = []
      project_id = [project_id] unless project_id.is_a? Array
      project_id.each do |id|
        project = Project.find(id)
        project_ids << id.to_i
        project_ids << project_children_ids(project)
      end
      project_ids.flatten.uniq.sort
    end
    
    def self.project_children_ids(project)
      project.children.collect { |child| [child.id, project_children_ids(child)] }
    end

  end
end
