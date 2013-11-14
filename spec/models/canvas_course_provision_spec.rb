require "spec_helper"

describe CanvasCourseProvision do
  let(:instructor_id) { rand(99999).to_s }
  let(:user_id) { rand(99999).to_s }
  let(:teaching_semesters) {
    [
      {
        :name => 'Fall 2013',
        :slug => 'fall-2013',
        :classes => [
          {
            :course_number => "ENGIN 7",
            :dept => "ENGIN",
            :slug => "engin-7",
            :title => "Introduction to Computer Programming for Scientists and Engineers",
            :role => "Instructor",
            :sections => [
              { :ccn => "#{rand(99999)}", :instruction_format => "DIS", :is_primary_section => false, :section_label => "DIS 102", :section_number => "102" }
            ]
          }
        ]
      }
    ]
  }
  before { CanvasProvideCourseSite.stub(:new).with(instructor_id).and_return(double(candidate_courses_list: teaching_semesters)) }
  before { CanvasProvideCourseSite.stub(:new).with(user_id).and_return(double(candidate_courses_list: [])) }

  describe "#get_feed" do
    context 'when delegating' do
      subject { CanvasCourseProvision.new(user_id, as_instructor: instructor_id) }

      context 'when a mischiefmaker' do
        before { UserAuth.stub(:is_superuser?).with(user_id).and_return(false) }
        before { CanvasAdminsProxy.any_instance.stub(:admin_user?).with(user_id).and_return(false) }
        its(:user_authorized?) { should be_false }
        its(:get_feed) {should be_nil }
      end

      context 'when a Canvas admin' do
        before { UserAuth.stub(:is_superuser?).with(user_id).and_return(false) }
        before { CanvasAdminsProxy.any_instance.stub(:admin_user?).with(user_id).and_return(true) }
        its(:user_authorized?) { should be_true }
        it "should find courses" do
          feed = subject.get_feed
          expect(feed[:is_admin]).to be_true
          expect(feed[:acting_as]).to eq instructor_id
          expect(feed[:teaching_semesters]).to eq teaching_semesters
        end
      end

      context 'when a superuser' do
        before { UserAuth.stub(:is_superuser?).with(user_id).and_return(true) }
        before { CanvasAdminsProxy.any_instance.stub(:admin_user?).with(user_id).and_return(false) }
        its(:user_authorized?) { should be_true }
      end

    end

    context 'when not delegating' do
      subject { CanvasCourseProvision.new(user_id) }
      its(:user_authorized?) { should be_true }
      it "should have empty feed" do
        feed = subject.get_feed
        expect(feed[:is_admin]).to be_false
        expect(feed[:acting_as]).to be_nil
        expect(feed[:teaching_semesters]).to be_empty
      end
    end

    context 'when instructor' do
      subject { CanvasCourseProvision.new(instructor_id) }
      its(:user_authorized?) { should be_true }
      it "should have courses" do
        feed = subject.get_feed
        expect(feed[:is_admin]).to be_false
        expect(feed[:acting_as]).to be_nil
        expect(feed[:teaching_semesters]).to eq teaching_semesters
      end
    end
  end

  describe "#create_course_site" do
    subject { CanvasCourseProvision.new(instructor_id) }
    it "returns nil if user is not authorized" do
      subject.should_receive(:user_authorized?).and_return(false)
      subject.create_course_site("fall-2013", ["1136", "1204"]).should be_nil
    end

    it "returns canvas course provision job id" do
      cpcs = double()
      cpcs.stub(:background).and_return(cpcs)
      cpcs.stub(:create_course_site).and_return(true)
      cpcs.stub(:job_id).and_return('canvas.courseprovision.1234.1383330151057')
      CanvasProvideCourseSite.stub(:new).and_return(cpcs)

      subject.should_receive(:user_authorized?).and_return(true)
      result = subject.create_course_site("fall-2013", ["1136", "1204"])
      result.should == 'canvas.courseprovision.1234.1383330151057'
    end
  end

end
