require_relative '../test_helper'

describe DeployMailer do
  let(:stage) { stages(:test_staging) }
  let(:deploy) { Deploy.create!(stage: stage, job: job, commit: 'master') }
  let(:job) do
    Job.create!(command: '', project: projects(:test), user: users(:admin))
  end

  before do
    stage.update_attributes!(notify_email_address: 'test@test.com')
    DeployMailer.deploy_email(stage, deploy).deliver
  end

  subject do
    ActionMailer::Base.deliveries.first
  end

  it 'is from deploys@' do
    subject.from.must_equal(['deploys@zendesk.com'])
  end

  it 'sends to notify_email_address' do
    subject.to.must_equal(['test@test.com'])
  end

  it 'sets a subject' do
    subject.subject.wont_be_empty
  end
end