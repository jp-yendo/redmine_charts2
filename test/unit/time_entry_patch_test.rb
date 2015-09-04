require File.dirname(__FILE__) + '/../test_helper'

class TimeEntryPatchTest < ActiveSupport::TestCase

  def test_time_entry
    issue = Issue.new(:project_id => 15041, :tracker_id => 1, :author_id => 1, :status_id => 1, :priority => IssuePriority.all.first, :subject => 'test_create', :description => 'IssueTest#test_create')

    assert issue.save

    assert_equal 0, ChartTimeEntry.where(:issue_id => issue.id).size

    time_entry = TimeEntry.new(:issue_id => issue.id, :activity_id => 9, :hours => 2, :spent_on => Time.mktime(2010,3,11))
    time_entry.user_id = 1

    assert time_entry.save

    time_entries = ChartTimeEntry.where(:issue_id => issue.id).order("id asc")

    assert_equal 2, time_entries.size

    assert_equal 2010070, time_entries[0].day
    assert_equal 2010010, time_entries[0].week
    assert_equal 2010003, time_entries[0].month
    assert_equal issue.id, time_entries[0].issue_id
    assert_equal 15041, time_entries[0].project_id
    assert_equal 9, time_entries[0].activity_id
    assert_equal 1, time_entries[0].user_id
    assert_equal 2, time_entries[0].logged_hours
    assert_equal 1, time_entries[0].entries

    assert_equal 0, time_entries[1].day
    assert_equal 0, time_entries[1].week
    assert_equal 0, time_entries[1].month
    assert_equal issue.id, time_entries[1].issue_id
    assert_equal 15041, time_entries[1].project_id
    assert_equal 9, time_entries[1].activity_id
    assert_equal 1, time_entries[1].user_id
    assert_equal 2, time_entries[1].logged_hours
    assert_equal 1, time_entries[1].entries

    time_entry = tmp_time_entry = TimeEntry.new(:issue_id => issue.id, :activity_id => 9, :hours => 10, :spent_on => Time.mktime(2010,3,11))
    time_entry.user_id = 1

    assert time_entry.save

    time_entries = ChartTimeEntry.where(:issue_id => issue.id).order("id asc")

    assert_equal 2, time_entries.size

    assert_equal 2010070, time_entries[0].day
    assert_equal issue.id, time_entries[0].issue_id
    assert_equal 9, time_entries[0].activity_id
    assert_equal 1, time_entries[0].user_id
    assert_equal 12, time_entries[0].logged_hours
    assert_equal 2, time_entries[0].entries

    assert_equal 0, time_entries[1].day
    assert_equal issue.id, time_entries[1].issue_id
    assert_equal 9, time_entries[1].activity_id
    assert_equal 1, time_entries[1].user_id
    assert_equal 12, time_entries[1].logged_hours
    assert_equal 2, time_entries[1].entries

    time_entry = TimeEntry.new(:issue_id => issue.id, :activity_id => 9, :hours => 1, :spent_on => Time.mktime(2010,3,12))
    time_entry.user_id = 1

    assert time_entry.save

    time_entries = ChartTimeEntry.where(:issue_id => issue.id).order("id asc")

    assert_equal 3, time_entries.size

    assert_equal 2010070, time_entries[0].day
    assert_equal issue.id, time_entries[0].issue_id
    assert_equal 9, time_entries[0].activity_id
    assert_equal 1, time_entries[0].user_id
    assert_equal 12, time_entries[0].logged_hours
    assert_equal 2, time_entries[0].entries

    assert_equal 0, time_entries[1].day
    assert_equal issue.id, time_entries[1].issue_id
    assert_equal 9, time_entries[1].activity_id
    assert_equal 1, time_entries[1].user_id
    assert_equal 13, time_entries[1].logged_hours
    assert_equal 3, time_entries[1].entries

    assert_equal 2010071, time_entries[2].day
    assert_equal issue.id, time_entries[2].issue_id
    assert_equal 9, time_entries[2].activity_id
    assert_equal 1, time_entries[2].user_id
    assert_equal 1, time_entries[2].logged_hours
    assert_equal 1, time_entries[2].entries

    time_entry = TimeEntry.new(:issue_id => issue.id, :activity_id => 10, :hours => 1, :spent_on => Time.mktime(2010,3,12))
    time_entry.user_id = 1

    assert time_entry.save

    time_entries = ChartTimeEntry.where(:issue_id => issue.id).order("id asc")

    assert_equal 5, time_entries.size

    assert_equal 2010070, time_entries[0].day
    assert_equal issue.id, time_entries[0].issue_id
    assert_equal 9, time_entries[0].activity_id
    assert_equal 1, time_entries[0].user_id
    assert_equal 12, time_entries[0].logged_hours
    assert_equal 2, time_entries[0].entries

    assert_equal 0, time_entries[1].day
    assert_equal issue.id, time_entries[1].issue_id
    assert_equal 9, time_entries[1].activity_id
    assert_equal 1, time_entries[1].user_id
    assert_equal 13, time_entries[1].logged_hours
    assert_equal 3, time_entries[1].entries

    assert_equal 2010071, time_entries[2].day
    assert_equal issue.id, time_entries[2].issue_id
    assert_equal 9, time_entries[2].activity_id
    assert_equal 1, time_entries[2].user_id
    assert_equal 1, time_entries[2].logged_hours
    assert_equal 1, time_entries[2].entries

    assert_equal 2010071, time_entries[3].day
    assert_equal issue.id, time_entries[3].issue_id
    assert_equal 10, time_entries[3].activity_id
    assert_equal 1, time_entries[3].user_id
    assert_equal 1, time_entries[3].logged_hours
    assert_equal 1, time_entries[3].entries

    assert_equal 0, time_entries[4].day
    assert_equal issue.id, time_entries[4].issue_id
    assert_equal 10, time_entries[4].activity_id
    assert_equal 1, time_entries[4].user_id
    assert_equal 1, time_entries[4].logged_hours
    assert_equal 1, time_entries[4].entries

    time_entry.hours = 2
    assert time_entry.save

    time_entries = ChartTimeEntry.where(:issue_id => issue.id).order("id asc")

    assert_equal 2010071, time_entries[3].day
    assert_equal issue.id, time_entries[3].issue_id
    assert_equal 10, time_entries[3].activity_id
    assert_equal 1, time_entries[3].user_id
    assert_equal 2, time_entries[3].logged_hours
    assert_equal 1, time_entries[3].entries

    assert_equal 0, time_entries[4].day
    assert_equal issue.id, time_entries[4].issue_id
    assert_equal 10, time_entries[4].activity_id
    assert_equal 1, time_entries[4].user_id
    assert_equal 2, time_entries[4].logged_hours
    assert_equal 1, time_entries[4].entries

    tmp_time_entry.hours = 20
    assert tmp_time_entry.save

    time_entries = ChartTimeEntry.where(:issue_id => issue.id).order("id asc")

    assert_equal 2010070, time_entries[0].day
    assert_equal issue.id, time_entries[0].issue_id
    assert_equal 9, time_entries[0].activity_id
    assert_equal 1, time_entries[0].user_id
    assert_equal 22, time_entries[0].logged_hours
    assert_equal 2, time_entries[0].entries

    assert_equal 0, time_entries[1].day
    assert_equal issue.id, time_entries[1].issue_id
    assert_equal 9, time_entries[1].activity_id
    assert_equal 1, time_entries[1].user_id
    assert_equal 23, time_entries[1].logged_hours
    assert_equal 3, time_entries[1].entries

    issue.destroy

    assert_equal 0, ChartTimeEntry.where(:issue_id => issue.id).size
  end

end