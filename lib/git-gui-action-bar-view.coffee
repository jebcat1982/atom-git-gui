Git = require 'nodegit'
{$, View} = require 'space-pen'

class GitGuiActionBarView extends View
  startIndex: 0
  endIndex: 10
  @content: ->
    @div class: 'git-gui-action-bar', =>
      @ul class: 'list-group git-gui-action-bar-list', =>
        @li class: 'list-item', =>
          @a class: 'icon', id: 'commit-action'
        @li class: 'list-item', =>
          @a class: 'icon', id: 'push-action'
        @li class: 'list-item', =>
          @a class: 'icon', id: 'pull-action'
        @li class: 'list-item', =>
          @a class: 'icon', id: 'log-action'
        @li class: 'list-item', =>
          @a class: 'icon', id: 'settings-action'

  # TODO: Add an `amend` option for `commit`
  # TODO: Add an `merge` option for `pull`
  initialize: ->
    $(document).ready () =>
      # TODO: check if log is available via number of commits made
      $('#log-action').addClass('available')
      $('#settings-action').addClass('available')

      $('body').on 'mouseenter', '#push-action', () ->
        $('body').on 'keydown', (e) ->
          if e.which == 16
            if ! $('#push-action').hasClass('force')
              $('#push-action').addClass 'force'

        $('body').on 'keyup', (e) ->
          if e.which == 16
            if $('#push-action').hasClass('force')
              $('#push-action').removeClass 'force'

      $('body').on 'mouseleave', '#push-action', () ->
        if $('#push-action').hasClass('force')
          $('#push-action').removeClass 'force'
        $('body').off 'keydown'
        $('body').off 'keyup'

      $('body').on 'click', '#commit-action', () =>
        $('atom-workspace-axis.horizontal').toggleClass 'blur'
        $('#action-view').parent().show()
        $('#action-view').addClass 'open'
        @parentView.gitGuiActionView.openCommitAction()

      $('body').on 'click', '#push-action', () =>
        if $('#push-action').hasClass('force')
          atom.confirm
            message: "Force push?"
            detailedMessage: "This will overwrite changes to the remote."
            buttons:
              Ok: =>
                @parentView.gitGuiActionView.openPushAction(true)
              Cancel: ->
                return
        else
          @parentView.gitGuiActionView.openPushAction(false)

      $('body').on 'click', '#pull-action', () ->
        $('atom-workspace-axis.horizontal').toggleClass 'blur'
        $('#action-view').parent().show()
        $('#action-view').addClass 'open'
        # @parentView.gitGuiActionView.openPullAction()

      $('body').on 'click', '#log-action', () =>
        if $('#log').hasClass('open')
          $('.git-gui-staging-area').removeClass('fade-and-blur')
          $('#settings-action').addClass('available')
          $('#log').removeClass('open')
          $('#log').empty()
          @startIndex = 0
          @endIndex = 10
        else
          @updateLog()
          $('.git-gui-staging-area').addClass('fade-and-blur')
          $('#settings-action').removeClass('available')
          $('#log').addClass('open')

      $('body').on 'click', '#settings-action', () ->
        if $('#settings').hasClass('open')
          $('#settings').removeClass('open')
          $('#log-action').addClass('available')
        else
          $('#settings').addClass('open')
          $('#log-action').removeClass('available')

        $('.git-gui-staging-area').toggleClass('fade-and-blur')

  serialize: ->

  destroy: ->

  update: ->
    pathToRepo = $('#git-gui-project-list').find(':selected').data('repo')
    Git.Repository.open pathToRepo
    .then (repo) =>
      @updateCommitAction repo
      @updatePushAction repo
    .catch (error) ->
      atom.notifications.addError "#{error}"
      console.log error

  updateCommitAction: (repo) ->
    statusOptions = new Git.StatusOptions()
    Git.StatusList.create repo, statusOptions
    .then (statusList) ->
      do () ->
        $('#commit-action').removeClass 'available'
        for i in [0...statusList.entrycount() ]
          entry = Git.Status.byIndex(statusList, i)
          status = entry.status()
          switch status
            when Git.Status.STATUS.INDEX_NEW, \
                 Git.Status.STATUS.INDEX_MODIFIED, \
                 Git.Status.STATUS.INDEX_NEW + Git.Status.STATUS.INDEX_MODIFIED, \
                 Git.Status.STATUS.INDEX_DELETED, \
                 Git.Status.STATUS.INDEX_RENAMED, \
                 Git.Status.STATUS.INDEX_MODIFIED + Git.Status.STATUS.WT_MODIFIED
              $('#commit-action').addClass 'available'
              return
    .catch (error) ->
      atom.notifications.addError "#{error}"
      console.log error

  updatePushAction: (repo) ->
    if repo.isEmpty()
      return
    Git.Remote.list(repo)
    .then (remotes) ->
      if remotes.length != 0
        repo.getCurrentBranch()
        .then (ref) ->
          Git.Reference.nameToId repo, ref.name()
          .then (local) ->
            # TODO: Consider the case when a user wants to get the ahead/behind
            #       count from a remote other than origin.
            Git.Reference.nameToId repo, "refs/remotes/origin/#{ref.shorthand()}"
            .then (upstream) ->
              Git.Graph.aheadBehind(repo, local, upstream)
              .then (aheadbehind) ->
                if aheadbehind.ahead
                  $('#push-action').addClass 'available'
                else
                  $('#push-action').removeClass 'available'
                if aheadbehind.behind
                  $('#pull-action').addClass 'available'
                else
                  $('#pull-action').removeClass 'available'
    .catch (error) ->
      atom.notifications.addError "#{error}"
      console.log error

  updateLog: () ->
    pathToRepo = $('#git-gui-project-list').find(':selected').data('repo')
    Git.Repository.open pathToRepo
    .then (repo) =>
      repo.getHeadCommit()
      .then (commit) =>
        if commit == null
          return
        history = commit.history Git.Revwalk.SORT.Time
        promise = new Promise (resolve, reject) ->
          history.on "end", resolve
          history.on "error", reject
        history.start()
        promise.then (commits) =>
          if @startIndex > commits.length
            return
          endIndex = if @endIndex > commits.length then commits.length else @endIndex
          for i in [@startIndex...endIndex]
            @startIndex += 1
            @endIndex += 1
            div = $('<div></div>')
            commitDiv = $("<div>Commit: #{commits[i].sha()}</div>")
            authorDiv = $("<div>Author: #{commits[i].author().name()} &lt#{commits[i].author().email()}&gt</div>")
            dateDiv = $("<div>Date: #{commits[i].date()}</div>")
            messageDiv = $("<div>\n\t#{commits[i].message()}\n\n</div>")
            div.append commitDiv
            div.append authorDiv
            div.append dateDiv
            div.append messageDiv
            $('#log').append div
    .catch (error) ->
      atom.notifications.addError "#{error}"
      console.log error

module.exports = GitGuiActionBarView
