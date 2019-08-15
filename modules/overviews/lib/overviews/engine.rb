module Overviews
  class Engine < ::Rails::Engine
    isolate_namespace Overviews

    engine_name :overviews

    include OpenProject::Plugins::ActsAsOpEngine

    initializer 'overviews.menu' do
      ::Redmine::MenuManager.map(:project_menu) do |menu|
        menu.push(:overview,
                  { controller: 'overviews/overviews', action: 'show' },
                  caption: :'overviews.label',
                  param: :project_id,
                  first: true,
                  engine: :project_overviews,
                  icon: 'icon2 icon-info1')
      end
    end

    initializer 'overviews.permissions' do
      OpenProject::AccessControl.permission(:view_project)
        .actions
        .push('overviews/overviews/show')
      #OpenProject::AccessControl.map do |ac_map|
      #  ac_map.project_module(:dashboards) do |pm_map|
      #    pm_map.permission(:view_dashboards, 'dashboards/dashboards': ['show'])
      #    pm_map.permission(:manage_dashboards, 'dashboards/dashboards': ['show'])
      #  end
      #end
    end

    #initializer 'dashboards.conversion' do
    #  require Rails.root.join('config', 'constants', 'ar_to_api_conversions')

    #  Constants::ARToAPIConversions.add('grids/dashboard': 'grid')
    #end

    config.to_prepare do
      Overviews::GridRegistration.register!
    end
  end
end
