require 'spec_helper'

describe Canvas::CourseAssignments do

  let(:user_id)             { 2050 }
  let(:canvas_course_id)    { 1234001 }
  subject                   { Canvas::CourseAssignments.new(:course_id => canvas_course_id) }

  it 'provides course assignments' do
    assignments = subject.course_assignments
    expect(assignments).to be_an_instance_of Array
    expect(assignments.count).to eq 2
    expect(assignments[0]['id']).to eq 6175848
    expect(assignments[0]['name']).to eq 'Assignment 1'
    expect(assignments[0]['description']).to eq '<p>Assignment 1 description</p>'
    expect(assignments[0]['muted']).to eq false
    expect(assignments[0]['due_at']).to eq "2015-05-12T19:40:00Z"
    expect(assignments[0]['points_possible']).to eq 100

    expect(assignments[1]['id']).to eq 6175849
    expect(assignments[1]['name']).to eq "Assignment 2"
    expect(assignments[1]['description']).to eq '<p>Assignment 2 description</p>'
    expect(assignments[1]['muted']).to eq true
    expect(assignments[1]['due_at']).to eq nil
    expect(assignments[1]['points_possible']).to eq 50
  end

  it 'uses cache by default' do
    expect(Canvas::CourseAssignments).to receive(:fetch_from_cache).and_return([])
    assignments = subject.course_assignments
    expect(assignments).to be_an_instance_of Array
    expect(assignments.count).to eq 0
  end

  it 'bypasses cache when cache option is false' do
    expect(Canvas::CourseAssignments).to_not receive(:fetch_from_cache)
    assignments = subject.course_assignments(:cache => false)
    expect(assignments).to be_an_instance_of Array
    expect(assignments.count).to eq 2
  end
end
