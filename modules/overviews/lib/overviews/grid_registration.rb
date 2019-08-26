module Overviews
  class GridRegistration < ::Grids::Configuration::Registration
    grid_class 'Grids::Overview'
    to_scope :project_overview_path

    widgets 'work_packages_table',
            'work_packages_graph',
            'project_description',
            'project_details',
            'subprojects',
            'work_packages_calendar',
            'work_packages_overview',
            'time_entries_project',
            'members',
            'news',
            'documents',
            'custom_text'

    remove_query_lambda = -> {
      ::Query.find_by(id: options[:queryId])&.destroy
    }

    save_or_manage_queries_lambda = ->(user, project) {
      user.allowed_to?(:save_queries, project) &&
        user.allowed_to?(:manage_public_queries, project)
    }

    view_work_packages_lambda = ->(user, project) {
      user.allowed_to?(:view_work_packages, project)
    }

    widget_strategy 'work_packages_table' do
      after_destroy remove_query_lambda

      allowed save_or_manage_queries_lambda

      options_representer '::API::V3::Grids::Widgets::QueryOptionsRepresenter'
    end

    widget_strategy 'work_packages_graph' do
      after_destroy remove_query_lambda

      allowed save_or_manage_queries_lambda

      options_representer '::API::V3::Grids::Widgets::ChartOptionsRepresenter'
    end

    widget_strategy 'custom_text' do
      options_representer '::API::V3::Grids::Widgets::CustomTextOptionsRepresenter'
    end

    widget_strategy 'work_packages_overview' do
      allowed view_work_packages_lambda
    end

    widget_strategy 'work_packages_calendar' do
      allowed view_work_packages_lambda
    end

    widget_strategy 'members' do
      allowed ->(user, project) {
        user.allowed_to?(:view_members, project)
      }
    end

    widget_strategy 'news' do
      allowed ->(user, project) {
        user.allowed_to?(:view_news, project)
      }
    end

    widget_strategy 'documents' do
      allowed ->(user, project) {
        user.allowed_to?(:view_documents, project)
      }
    end

    defaults -> {
      {
        row_count: 2,
        column_count: 2,
        widgets: [
          {
            identifier: 'project_description',
            start_row: 1,
            end_row: 2,
            start_column: 1,
            end_column: 2,
            options: {
              name: I18n.t('js.grid.widgets.project_description.title')
            }
          },
          {
            identifier: 'project_details',
            start_row: 2,
            end_row: 3,
            start_column: 1,
            end_column: 2,
            options: {
              name: I18n.t('js.grid.widgets.project_details.title')
            }
          },
          {
            identifier: 'work_packages_overview',
            start_row: 1,
            end_row: 2,
            start_column: 2,
            end_column: 3,
            options: {
              name: I18n.t('js.grid.widgets.work_packages_overview.title')
            }
          },
          {
            identifier: 'members',
            start_row: 2,
            end_row: 3,
            start_column: 2,
            end_column: 3,
            options: {
              name: I18n.t('js.grid.widgets.members.title')
            }
          }
        ]
      }
    }

    validations :create, ->(*_args) {
      if Grids::Overview.where(project_id: model.project_id).exists?
        errors.add(:scope, :taken)
      end
    }

    validations :create, ->(*_args) {
      next if user.allowed_to?(:manage_overview, model.project)

      defaults = Overviews::GridRegistration.defaults

      %i[row_count column_count].each do |count|
        if model.send(count) != defaults[count]
          errors.add(count, :unchangeable)
        end
      end

      model.widgets.each do |widget|
        widget_default = defaults[:widgets].detect { |w| w[:identifier] == widget.identifier }

        if widget.attributes.except("options") != widget_default.attributes.except("options") ||
           widget.attributes["options"].stringify_keys != widget_default.attributes["options"].stringify_keys
          errors.add(:widgets, :unchangeable)
        end
      end
    }

    class << self
      def all_scopes
        view_allowed = Project.allowed_to(User.current, :view_project)

        projects = Project
                   .where(id: view_allowed)

        projects.map { |p| url_helpers.project_overview_path(p) }
      end

      def from_scope(scope)
        # recognize_routes does not work with engine paths
        path = [OpenProject::Configuration.rails_relative_url_root, 'projects', '([^/]+)', '?'].compact.join('/')
        match = Regexp.new(path).match(scope)
        return if match.nil?

        {
          class: ::Grids::Overview,
          project_id: match[1]
        }
      end

      def writable?(grid, user)
        # New records are allowed to be saved by everybody. Other parts
        # of the application prevent a user from saving arbitrary pages.
        # Only the default config is allowed and only one page per project is allowed.
        # That way, a new page can be created on the fly without the user noticing.
        super && (grid.new_record? || user.allowed_to?(:manage_overview, grid.project))
      end

      def visible(user = User.current)
        super
          .where(project_id: Project.allowed_to(user, :view_project))
      end
    end
  end
end
