module DemoData
  module Overviews
    class OverviewSeeder < Seeder
      include ::DemoData::References

      def seed_data!
        puts "*** Seeding Overview"

        Array(demo_data_for('projects')).each do |key, project|
          puts "   -Creating overview for #{project[:name]}"

          if (config = project[:"project-overview"])
            project = Project.find_by! identifier: project[:identifier]

            overview = Grids::Overview.create(config.slice(:row_count, :column_count).merge(project: project))

            config[:widgets].each do |widget_config|
              create_attachments!(overview, widget_config)

              if widget_config[:options] && widget_config[:options][:text]
                widget_config[:options][:text] = with_references(widget_config[:options][:text], project)
                widget_config[:options][:text] = link_attachments(widget_config[:options][:text], overview.attachments)
              end

              if widget_config[:options] && widget_config[:options][:queryId]
                widget_config[:options][:queryId] = with_references(widget_config[:options][:queryId], project)
              end

              overview.widgets.build(widget_config.except(:attachments))
            end

            overview.save!
          end
        end
      end

      def applicable?
        Grids::Overview.count.zero? && demo_projects_exist?
      end

      private

      def demo_projects_exist?
        identifiers = Array(demo_data_for('projects'))
          .map { |_key, project| project[:identifier] }

        identifiers
          .all? { |ident| Project.where(identifier: ident).exists? }
      end

      def create_attachments!(overview, attributes)
        Array(attributes[:attachments]).each do |file_name|
          attachment = overview.attachments.build
          attachment.author = User.admin.first
          attachment.file = File.new attachment_path(file_name)

          attachment.save!
        end
      end

      def attachment_path(file_name)
        ::Overviews::Engine.root.join(
          "config/locales/media/#{I18n.locale}/#{file_name}"
        )
      end
    end
  end
end
