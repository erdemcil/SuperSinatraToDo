require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'sinatra/flash'

SITE_TITLE = "Recall"
SITE_DESCRIPTION = "'cause you are too busy to remember"

enable :sessions

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

class Note
	include DataMapper::Resource
	property :id, Serial
	property :content, Text
	property :complete, Boolean, :required => true, :default =>false
	property :created_at, DateTime
	property :updated_at, DateTime
end


get '/' do
	@notes = Note.all :order => :id.desc
	@title = 'All Notes'
	if @notes.empty?
		flash[:error] = 'No notes found. Add your first below.'
	end
	erb:home
end

post '/' do
	n = Note.new
	n.content = params[:content]
	n.created_at = Time.now
	n.updated_at = Time.now
	if n.save
		redirect '/', flash[:notice] = 'Note created successfully.'
	else
		redirect '/', flash[:error] = 'Failed to save note!'
	end
end

get '/rss.xml' do
	@notes = Note.all :order => :id.desc
	builder:rss
end

get '/:id' do
 	@note = Note.get params[:id]
	@title = "Edit note ##{params[:id]}"
	erb :edit
end

put '/:id' do
	n = Note.get params[:id]
	n.content = params[:content]
	n.complete = params[:complete] ? 1 : 0
	n.updated_at = Time.now
	if n.save
		redirect '/', flash[:notice] = 'Note updated successfully.'
	else
		redirect '/', flash[:error] = 'Error updating note.'
	end
end

get '/:id/delete' do
	@note = Note.get params[:id]
	@title = "Confirm deletion of note ##{params[:id]}"
	if @note
		erb :delete
	else
		redirect '/', flash[:error] = 'Can not find that note.'
	end
end

delete '/:id' do
	n = Note.get params[:id]
	if n.destroy
		redirect '/', flash[:notice] = 'Note deleted successfully.'
	else
		redirect '/', flash[:error] = 'Error deleting note.'
	end
end

get '/:id/complete' do
	n = Note.get params[:id]
	unless n
		redirect '/', flash[:error] = 'Can not find that note.'
	end

	n.complete = n.complete ? 0 : 1
	n.updated_at = Time.now

	if n.save
		if n.complete = 1
			redirect '/', flash[:notice] = 'Note marked as done.'
		else
			redirect '/', flash[:notice] = 'Note marked as undone.'
		end
	else
		redirect '/', flash[:error] = 'Error marking note as done or undone.'
	end
end



DataMapper.finalize.auto_upgrade!

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end
