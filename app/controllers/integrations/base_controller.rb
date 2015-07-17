class Integrations::BaseController < ApplicationController
  skip_before_action :login_users
  skip_before_action :verify_authenticity_token

  def create
    return head :ok unless deploy?
    project.deploy_with_docker? ? create_docker_build : create_release_and_deploy
  end

  protected

  def create_new_release
    if project.create_releases_for_branch?(branch)
      if project.last_release_contains_commit?(commit)
        project.releases.order(:id).last
      else
        release_service = ReleaseService.new(project)
        release_service.create_release!(commit: commit, author: user)
      end
    end
  end

  def deploy_to_stages
    stages = project.webhook_stages_for(branch, service_type, service_name)
    deploy_service = DeployService.new(user)

    stages.all? do |stage|
      deploy_service.deploy!(stage, reference: commit).persisted?
    end
  end

  def project
    @project ||= Project.find_by_token!(params[:token])
  end

  def contains_skip_token?(message)
    ["[deploy skip]", "[skip deploy]"].any? do |token|
      message.include?(token)
    end
  end

  def user
    name = self.class.name.split("::").last.sub("Controller", "")
    email = "deploy+#{name.underscore}@#{Rails.application.config.samson.email.sender_domain}"

    User.create_with(name: name, integration: true).find_or_create_by(email: email)
  end

  private

  def service_type
    'ci'
  end

  def service_name
    @service_name ||= self.class.name.demodulize.sub('Controller', '').downcase
  end

  def create_docker_build
    release = create_new_release
    build = project.builds.create(
      git_ref: branch,
      git_sha: commit,
      description: message,
      creator: user,
      label: release.version)
    build.persisted? ? head(:ok) : head(:bad_request, message: build.errors)
  end

  def create_release_and_deploy
    create_new_release
    return head :unprocessable_entity unless deploy_to_stages
    head :ok
  end

  def message
    ''
  end
end
