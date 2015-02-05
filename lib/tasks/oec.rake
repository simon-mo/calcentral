namespace :oec do

  hr = "\n" + '-------------------------------------------------------------' + "\n"
  src_dir = ENV['src'].to_s == '' ? Dir.pwd : ENV['src']
  dest_dir = ENV['dest'].to_s == '' ? Dir.pwd : ENV['dest']
  biology_dept_name = 'BIOLOGY'

  desc 'Export courses.csv file'
  task :courses => :environment do
    files_created = []
    dept_set = Settings.oec.departments.to_set
    dept_set.each do |dept_name|
      exporter = Oec::Courses.new(dept_name, dest_dir)
      exporter.export
      files_created << "#{dest_dir}/#{exporter.base_file_name}.csv"
    end
    Oec::BiologyPostProcessor.new(dest_dir).post_process if dept_set.include? biology_dept_name
    Rails.logger.warn "#{hr}Files created:#{"\n " + files_created.join("\n ")}#{hr}"
  end

  desc 'Generate student files based on courses.csv input'
  task :students => :environment do
    dept_set = Settings.oec.departments.to_set
    if dept_set.include? biology_dept_name
      dept_set.add 'INTEGBI'
      dept_set.add 'MCELLBI'
    end
    ccn_set = Set.new
    gsi_ccn_set = Set.new
    dept_set.each do |dept_name|
      filename = "#{dept_name.gsub(/\s/, '_')}_courses.csv"
      csv_file = "#{src_dir}/#{filename}"
      if File.exists? csv_file
        reader = Oec::FileReader.new csv_file
        ccn_set.merge reader.ccns.to_set
        gsi_ccn_set.merge reader.gsi_ccns.to_set
      elsif dept_name == biology_dept_name
        Rails.logger.info "As expected, #{biology_dept_name} CSV not found. BIO entries are in MCELLBI, etc."
      else
        Rails.logger.warn <<-eos
        #{hr}File not found: #{csv_file}
        Usage: rake oec:students [src=/path/to/source/] [dest=/export/path/]#{hr}
        eos
        raise ArgumentError, "Directory does not exist or is missing expected CSV file(s): #{src_dir}"
      end
    end
    [Oec::Students, Oec::CourseStudents].each do |klass|
      klass.new(ccn_set, gsi_ccn_set, dest_dir).export
    end
    Rails.logger.warn "#{hr}Files wrote to #{dest_dir}#{hr}"
  end

  desc 'Spreadsheet from dept is compared with campus data'
  task :diff => :environment do
    dept_name = ENV['dept_name']
    if dept_name.to_s == ''
      Rails.logger.warn "#{hr}Usage: rake oec:diff dept_name=BIOLOGY [src=/path/to/files] [dest=/export/path/]#{hr}"
    else
      # Replace underscores in dept_name
      Oec::CoursesDiff.new(dept_name.upcase.gsub(/_/, ' '), src_dir, dest_dir).export
      Rails.logger.warn "#{hr}File wrote to #{dest_dir}#{hr}"
    end
  end

end
