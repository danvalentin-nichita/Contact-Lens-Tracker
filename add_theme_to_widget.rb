require 'xcodeproj'

project_path = 'ContactLensTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

widget_target = project.targets.find { |t| t.name == 'ContactLensWidgetExtension' }
if widget_target.nil?
    puts "Widget target not found"
    exit 1
end

app_theme_ref = project.files.find { |f| f.path =~ /AppTheme\.swift/ || f.name =~ /AppTheme\.swift/ }

if app_theme_ref.nil?
    puts "Could not find existing reference, creating new one"
    app_theme_ref = project.main_group.new_file('ContactLensTracker/AppTheme.swift')
end

sources_build_phase = widget_target.source_build_phase
unless sources_build_phase.files_references.include?(app_theme_ref)
    sources_build_phase.add_file_reference(app_theme_ref)
    puts "Added AppTheme.swift to ContactLensWidget target"
else
    puts "AppTheme.swift is already in ContactLensWidget target"
end

project.save
puts "Project saved successfully"
