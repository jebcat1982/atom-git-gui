{CompositeDisposable} = require 'atom'
{$, View} = require 'space-pen'
GitGuiActionBarView = require './git-gui-action-bar-view'
GitGuiActionView = require './git-gui-action-view'
GitGuiStagingAreaView = require './git-gui-staging-area-view'
GitGuiDiffView = require './git-gui-diff-view'
GitGuiSettingsView = require './git-gui-settings-view'

module.exports =
  class GitGuiView extends View
    @content: ->
      @div class: 'git-gui', =>
        @subview 'gitGuiDiffView', new GitGuiDiffView()
        @div class: 'git-gui-overlay', =>
          @subview 'gitGuiActionBarView', new GitGuiActionBarView()
          @subview 'gitGuiStatusView', new GitGuiStagingAreaView()
          @subview 'gitGuiSettingsView', new GitGuiSettingsView()

    initialize: ->
      @subscriptions = new CompositeDisposable

      @gitGuiActionView = new GitGuiActionView()
      @modalPanel = atom.workspace.addModalPanel
        item: @gitGuiActionView,
        visible: true
      @gitGuiActionView.parentView = this

      repo = atom.project.getRepositories()[0]

      @subscriptions.add repo.onDidChangeStatus () =>
        @updateAll()

      @subscriptions.add repo.onDidChangeStatuses () =>
        @updateAll()

      @subscriptions.add @gitGuiActionView.onDidCommit () =>
        @updateAll()

      @subscriptions.add @gitGuiActionView.onDidPush () =>
        @updateAll()

    serialize: ->

    destroy: ->
      @gitGuiActionBarView.destroy()
      @gitGuiActionView.destroy()
      @gitGuiStatusView.destroy()
      @gitGuiDiffView.destroy()
      @gitGuiSettingsView.destroy()
      @subscriptions.dispose()

    updateAll: ->
      @gitGuiActionBarView.updateActionBar()
      @gitGuiStatusView.updateStatuses()

    open: ->
      if $('.git-gui').hasClass 'open'
        return

      @updateAll()
      $('.git-gui').addClass 'open'

    close: ->
      if ! $('.git-gui').hasClass 'open'
        return

      $('.git-gui').removeClass 'open'

    isOpen: ->
      if $('.git-gui').hasClass 'open'
        return true
      return false
