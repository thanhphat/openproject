module ::Overviews
  class OverviewsController < ::ApplicationController
    before_action :find_optional_project
    before_action :authorize
    before_action :jump_to_project_menu_item

    menu_item :overview

    def jump_to_project_menu_item
      if params[:jump]
        # try to redirect to the requested menu item
        redirect_to_project_menu_item(@project, params[:jump]) && return
      end
    end

    def show
      render layout: 'angular'
    end
  end
end
