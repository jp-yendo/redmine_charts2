require File.dirname(__FILE__) + '/../test_helper'

class IssuePatchTest < ActiveSupport::TestCase

  def test_issue_status
    Time.set_current_date = Time.mktime(2010,3,11)

    issue = Issue.new(:project_id => 15041, :tracker_id => 1, :author_id => 1, :status_id => 1, :priority => IssuePriority.all.first, :subject => 'test_create', :description => 'IssueTest#test_create')
    assert issue.save
    issue.reload

    issue_status = ChartIssueStatus.where(:issue_id => issue.id)

    assert_equal 1, issue_status.size

    assert_equal 2010070, issue_status[0].day
    assert_equal 2010010, issue_status[0].week
    assert_equal 2010003, issue_status[0].month
    assert_equal issue.id, issue_status[0].issue_id
    assert_equal 15041, issue_status[0].project_id
    assert_equal 1, issue_status[0].status_id

    issue.status_id = 2
    assert issue.save

    issue_status = ChartIssueStatus.where(:issue_id => issue.id)

    assert_equal 1, issue_status.size
    assert_equal 2, issue_status[0].status_id

    Time.set_current_date = Time.mktime(2010,3,12)

    issue.status_id = 3
    assert issue.save

    issue_status = ChartIssueStatus.where(:issue_id => issue.id)

    assert_equal 2, issue_status.size

    assert_equal 2, issue_status[0].status_id
    assert_equal 3, issue_status[1].status_id

    issue.destroy
  end

  def test_done_ratio_if_status_is_finished
    Time.set_current_date = Time.mktime(2010,3,11)

    issue = Issue.new(:project_id => 15041, :tracker_id => 1, :author_id => 1, :status_id => 1, :priority => IssuePriority.all.first, :subject => 'test_create', :description => 'IssueTest#test_create')
    assert issue.save
    issue.reload

    issue.status_id = 5
    assert issue.save

    done_ratio = ChartDoneRatio.where(:issue_id => issue.id)

    assert_equal 2, done_ratio.size

    assert_equal 100, done_ratio[0].done_ratio
    assert_equal 100, done_ratio[1].done_ratio

    issue.destroy
  end

  def test_done_ratio
    Time.set_current_date = Time.mktime(2010,3,11)

    issue = Issue.new(:project_id => 15041, :tracker_id => 1, :author_id => 1, :status_id => 1, :priority => IssuePriority.all.first, :subject => 'test_create', :description => 'IssueTest#test_create')
    assert issue.save
    issue.reload

    assert_equal 0, ChartDoneRatio.where(:issue_id => issue.id).size

    issue.done_ratio = 10
    issue.save

    done_ratio = ChartDoneRatio.where(:issue_id => issue.id).order("id asc")

    assert_equal 2, done_ratio.size

    assert_equal 0, done_ratio[0].day
    assert_equal 0, done_ratio[0].week
    assert_equal 0, done_ratio[0].month
    assert_equal issue.id, done_ratio[0].issue_id
    assert_equal 15041, done_ratio[0].project_id
    assert_equal 10, done_ratio[0].done_ratio

    assert_equal 2010070, done_ratio[1].day
    assert_equal 2010010, done_ratio[1].week
    assert_equal 2010003, done_ratio[1].month
    assert_equal issue.id, done_ratio[1].issue_id
    assert_equal 15041, done_ratio[1].project_id
    assert_equal 10, done_ratio[1].done_ratio

    issue.done_ratio = 20
    issue.save

    done_ratio = ChartDoneRatio.where(:issue_id => issue.id).order("id asc")

    assert_equal 2, done_ratio.size
    assert_equal 20, done_ratio[0].done_ratio
    assert_equal 20, done_ratio[1].done_ratio

    Time.set_current_date = Time.mktime(2010,3,12)

    issue.done_ratio = 30
    issue.save

    done_ratio = ChartDoneRatio.where(:issue_id => issue.id).order("id asc")

    assert_equal 3, done_ratio.size
    assert_equal 30, done_ratio[0].done_ratio
    assert_equal 20, done_ratio[1].done_ratio
    assert_equal 30, done_ratio[2].done_ratio

    issue.destroy

    assert_equal 0, ChartDoneRatio.where(:issue_id => issue.id).size
  end

  def test_done_ratio_creation_with_done_ratio
    issue = Issue.new(:project_id => 15041, :tracker_id => 1, :author_id => 1, :status_id => 1, :priority => IssuePriority.all.first, :subject => 'test_create', :description => 'IssueTest#test_create', :done_ratio => 20)
    assert issue.save
    issue.reload

    assert_equal 2, ChartDoneRatio.where(:issue_id => issue.id).size

    issue.destroy

    assert_equal 0, ChartDoneRatio.where(:issue_id => issue.id).size
  end

end