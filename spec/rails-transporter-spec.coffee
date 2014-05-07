path = require 'path'
fs = require 'fs'
temp = require 'temp'
wrench = require 'wrench'


{$, WorkspaceView, Point} = require 'atom'
RailsTransporter = require '../lib/rails-transporter'

describe "RailsTransporter", ->
  activationPromise = null
  [viewFinderView, workspaceView, editor] = []

  beforeEach ->
    # set Project Path to temporaly directory.
    tempPath = fs.realpathSync(temp.mkdirSync('atom'))
    fixturesPath = atom.project.getPath()
    wrench.copyDirSyncRecursive(fixturesPath, tempPath, forceDelete: true)
    atom.project.setPath(path.join(tempPath, 'rals-transporter'))

    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('rails-transporter')

  describe "view-finder behavior", ->
    beforeEach ->
      atom.workspaceView.openSync(path.join(atom.project.getPath(), 'app/controllers/blogs_controller.rb'))

    describe "when the rails-transporter:toggle-view-finder event is triggered", ->
      it "shows the ViewFinder or hides it if it's already showing", ->
        expect(atom.workspaceView.find('.select-list')).not.toExist()
        
        # This is an activation event, triggering it will cause the package to be
        # activated.
        atom.workspaceView.trigger 'rails-transporter:toggle-view-finder'

        # Waits until package is activated
        waitsForPromise ->
          activationPromise

        runs ->
          expect(atom.workspaceView.find('.select-list')).toExist()
          atom.workspaceView.trigger 'rails-transporter:toggle-view-finder'
          expect(atom.workspaceView.find('.select-list')).not.toExist()

      it "shows all relative view paths for the current controller and selects the first", ->
        atom.workspaceView.trigger 'rails-transporter:toggle-view-finder'
      
        # Waits until package is activated
        waitsForPromise ->
          activationPromise

        runs ->
          viewDir = path.join(atom.project.getPath(), "app/views/blogs/")
          expect(atom.workspaceView.find('.select-list li').length).toBe fs.readdirSync(viewDir).length
          for view in fs.readdirSync(viewDir)
            expect(atom.workspaceView.find(".select-list .primary-line:contains(#{view})")).toExist()
            expect(atom.workspaceView.find(".select-list .secondary-line:contains(#{path.join(viewDir, view)})")).toExist()

          expect(atom.workspaceView.find(".select-list li:first")).toHaveClass 'two-lines selected'

  describe "open-model behavior", ->
    beforeEach ->
      atom.workspaceView.openSync(path.join(atom.project.getPath(), 'app/controllers/blogs_controller.rb'))

    it "opens model related controller if active editor is controller", ->
      atom.workspaceView.trigger 'rails-transporter:open-model'

      # Waits until package is activated and active panes count is 2
      waitsFor ->
        activationPromise
        atom.workspaceView.getActivePane().getItems().length == 2
        
      runs ->
        modelPath = path.join(atom.project.getPath(), "app/models/blog.rb")
        expect(atom.workspace.getActiveEditor().getPath()).toBe modelPath

  describe "open-helper behavior", ->
    beforeEach ->
      atom.workspaceView.openSync(path.join(atom.project.getPath(), 'app/controllers/blogs_controller.rb'))

    it "opens helper related controller if active editor is controller", ->
      atom.workspaceView.trigger 'rails-transporter:open-helper'

      # Waits until package is activated and active panes count is 2
      waitsFor ->
        activationPromise
        atom.workspaceView.getActivePane().getItems().length == 2
        
      runs ->
        modelPath = path.join(atom.project.getPath(), "app/helpers/blogs_helper.rb")
        expect(atom.workspace.getActiveEditor().getPath()).toBe modelPath

  describe "open-patial-template", ->
    beforeEach ->
      atom.workspaceView.openSync(path.join(atom.project.getPath(), 'app/views/blogs/edit.html.erb'))
      editorView = atom.workspaceView.getActiveView()
      editor = editorView.getEditor()

    describe "when current line is simple render method", ->
      it "opens partial template", ->
        editor.setCursorBufferPosition new Point(2, 0)
        atom.workspaceView.trigger 'rails-transporter:open-partial-template'

        # Waits until package is activated and active panes count is 2
        waitsFor ->
          activationPromise
          atom.workspaceView.getActivePane().getItems().length == 2
          
        runs ->
          partialPath = path.join(atom.project.getPath(), "app/views/blogs/_form.html.erb")
          expect(atom.workspace.getActiveEditor().getPath()).toBe partialPath

    describe "when current line is render method including ':partial =>'", ->
      it "opens partial template", ->
        editor.setCursorBufferPosition new Point(3, 0)
        atom.workspaceView.trigger 'rails-transporter:open-partial-template'

        # Waits until package is activated and active panes count is 2
        waitsFor ->
          activationPromise
          atom.workspaceView.getActivePane().getItems().length == 2
          
        runs ->
          partialPath = path.join(atom.project.getPath(), "app/views/blogs/_form.html.erb")
          expect(atom.workspace.getActiveEditor().getPath()).toBe partialPath

    describe "when current line is render method including 'partial:'", ->
      it "opens partial template", ->
        editor.setCursorBufferPosition new Point(4, 0)
        atom.workspaceView.trigger 'rails-transporter:open-partial-template'

        # Waits until package is activated and active panes count is 2
        waitsFor ->
          activationPromise
          atom.workspaceView.getActivePane().getItems().length == 2
          
        runs ->
          partialPath = path.join(atom.project.getPath(), "app/views/blogs/_form.html.erb")
          expect(atom.workspace.getActiveEditor().getPath()).toBe partialPath

    describe "when current line is render method with shared partial", ->
      it "opens shared partial template", ->
        editor.setCursorBufferPosition new Point(5, 0)
        atom.workspaceView.trigger 'rails-transporter:open-partial-template'

        # Waits until package is activated and active panes count is 2
        waitsFor ->
          activationPromise
          atom.workspaceView.getActivePane().getItems().length == 2
          
        runs ->
          partialPath = path.join(atom.project.getPath(), "app/views/shared/_form.html.erb")
          expect(atom.workspace.getActiveEditor().getPath()).toBe partialPath
          
  describe "open spec behavior", ->
    describe "when current editor opens controller", ->
      beforeEach ->
        atom.workspaceView.openSync(path.join(atom.project.getPath(), 'app/controllers/blogs_controller.rb'))

      it "opens controller spec related current controller", ->
        atom.workspaceView.trigger 'rails-transporter:open-spec'

        waitsFor ->
          activationPromise
          atom.workspaceView.getActivePane().getItems().length == 2
          
        runs ->
          specPath = path.join(atom.project.getPath(), "spec/controllers/blogs_controller_spec.rb")
          expect(atom.workspace.getActiveEditor().getPath()).toBe specPath
      
    describe "when current editor opens model", ->
      beforeEach ->
        atom.workspaceView.openSync(path.join(atom.project.getPath(), 'app/models/blog.rb'))

      it "opens model spec related current model", ->
        atom.workspaceView.trigger 'rails-transporter:open-spec'

        waitsFor ->
          activationPromise
          atom.workspaceView.getActivePane().getItems().length == 2
          
        runs ->
          specPath = path.join(atom.project.getPath(), "spec/models/blog_spec.rb")
          expect(atom.workspace.getActiveEditor().getPath()).toBe specPath
