require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    data = DB[:conn].execute("PRAGMA table_info('#{self.table_name}')")
    data.each.with_object([]) {|column_hash, array| array << column_hash["name"]}.compact
  end

  def initialize(options={})
    options.each {|key, value| self.send("#{key.to_s}=", value) unless value.nil?}
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.reject {|x| x == "id"}.join(", ")
  end

  def values_for_insert
    self.instance_variables.map {|x| x.to_s.tr('@', '')}.map {|x| "'#{self.send("#{x}")}'"}.join(", ")
  end

  def save
    DB[:conn].execute("INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert}) VALUES (#{self.values_for_insert});")
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
    self
  end

  def self.find_by_name(name)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = '#{name}'")
  end

  def self.find_by(attr)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{attr.keys.first.to_s} = '#{attr.values.first}'")
  end

end
