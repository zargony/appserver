require 'tempfile'

class Hash
  def symbolize_keys!
    keys.each { |key| self[key.to_sym] = delete(key) }
    self
  end
end

class File
  def self.safe_replace (filename)
    tempfile = Tempfile.new(File.basename(filename) + '.', File.dirname(filename))
    if File.exist?(filename)
      tempfile.chown(File.stat(filename).uid, File.stat(filename).gid)
      tempfile.chmod(File.stat(filename).mode)
    end
    yield tempfile
    tempfile.close
    File.unlink(filename) if File.exist?(filename)
    File.rename(tempfile, filename)
  end
end
