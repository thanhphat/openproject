module ::Overviews
  class OverviewsController < ::ApplicationController
    before_action :find_optional_project
    before_action :authorize

    menu_item :overview

    def show
      render layout: 'angular'
    end
  end
end
