#########################################################################
# This file is part of CoCalc: Copyright © 2020 Sagemath, Inc.
# License: AGPLv3 s.t. "Commons Clause" – see LICENSE.md for details
#########################################################################

underscore = require('underscore')

{React, ReactDOM, Actions, Store, rtypes, rclass, Redux}  = require('./app-framework')

{Col, Row, Button, FormControl, FormGroup, Well, InputGroup, Alert, Checkbox} = require('react-bootstrap')
{Icon, Loading, SearchInput, Space, ImmutablePureRenderMixin} = require('./r_misc')
misc            = require('smc-util/misc')
misc_page       = require('./misc_page')
{webapp_client} = require('./webapp_client')
{PathLink} = require('./project/new')


ProjectSearchInput = rclass
    displayName : 'ProjectSearch-ProjectSearchInput'

    mixins: [ImmutablePureRenderMixin]

    propTypes :
        user_input : rtypes.string.isRequired
        actions    : rtypes.object.isRequired

    clear_output: ->
        @props.actions.setState
            most_recent_path   : undefined
            command            : undefined
            most_recent_search : undefined
            search_results     : undefined
            search_error       : undefined

    handle_change: (value) ->
        @props.actions.setState(user_input : value)

    render: ->
        <SearchInput
            ref         = 'project_search_input'
            autoFocus   = {true}
            type        = 'search'
            value       = {@props.user_input}
            placeholder = 'Enter search (supports regular expressions!)'
            on_change   = {@handle_change}
            on_submit   = {@props.actions.search}
            on_clear    = {@clear_output}
        />

ProjectSearchOutput = rclass
    displayName : 'ProjectSearch-ProjectSearchOutput'

    propTypes :
        results          : rtypes.array
        too_many_results : rtypes.bool
        search_error     : rtypes.string
        most_recent_path : rtypes.string
        actions          : rtypes.object.isRequired

    too_many_results: ->
        <Alert bsStyle='warning'>
            There were more results than displayed below. Try making your search more specific.
        </Alert>

    get_results: ->
        if @props.search_error?
            return <Alert bsStyle='warning'>Search error: {@props.search_error} Please
                    try again with a more restrictive search</Alert>
        if @props.results?.length == 0
            return <Alert bsStyle='warning'>There were no results for your search</Alert>
        for i, result of @props.results
            <ProjectSearchResultLine
                key              = {i}
                filename         = {result.filename}
                description      = {result.description}
                line_number      = {result.line_number}
                most_recent_path = {@props.most_recent_path}
                actions          = {@props.actions} />

    render: ->
        results_well_styles =
            backgroundColor : 'white'
            fontFamily      : 'monospace'

        <div>
            {@too_many_results() if @props.too_many_results}
            <Well style={results_well_styles}>
                {@get_results()}
            </Well>
        </div>

ProjectSearchOutputHeader = rclass
    displayName : 'ProjectSearch-ProjectSearchOutputHeader'

    propTypes :
        most_recent_path   : rtypes.string.isRequired
        command            : rtypes.string
        most_recent_search : rtypes.string.isRequired
        search_results     : rtypes.array
        info_visible       : rtypes.bool
        search_error       : rtypes.string
        actions            : rtypes.object.isRequired

    getDefaultProps: ->
        info_visible : false

    output_path: ->
        path = @props.most_recent_path
        if path is ''
            return <Icon name='home' />
        return path

    change_info_visible: ->
        @props.actions.setState(info_visible : not @props.info_visible)

    get_info: ->
        <Alert bsStyle='info'>
            <ul>
                <li>
                    Search command (in a terminal): <pre>{@props.command}</pre>
                </li>
                <li>
                    Number of results: {@props.search_error ? @props.search_results?.length ? <Loading />}
                </li>
            </ul>
        </Alert>

    render: ->
        <div style={wordWrap:'break-word'}>
            <span style={color:'#666'}>
                <a onClick={=>@props.actions.set_active_tab('files')}
                   style={cursor:'pointer'} >Navigate to a different folder</a> to search in it.
            </span>

            <h4>
                Results of searching in {@output_path()} for
                "{@props.most_recent_search}"
                <Space/>
                <Button bsStyle='info' onClick={@change_info_visible}>
                    <Icon name='info-circle' /> How this works...
                </Button>
            </h4>

            {@get_info() if @props.info_visible}
        </div>

ProjectSearchBody = rclass ({name}) ->
    displayName : 'ProjectSearchBody'

    reduxProps :
        "#{name}" :
            current_path       : rtypes.string
            user_input         : rtypes.string
            search_results     : rtypes.array
            search_error       : rtypes.string
            too_many_results   : rtypes.bool
            command            : rtypes.string
            most_recent_search : rtypes.string
            most_recent_path   : rtypes.string
            subdirectories     : rtypes.bool
            case_sensitive     : rtypes.bool
            hidden_files       : rtypes.bool
            info_visible       : rtypes.bool
            git_grep           : rtypes.bool

    propTypes :
        actions : rtypes.object.isRequired

    getDefaultProps: ->
        user_input : ''

    valid_search: ->
        return @props.user_input.trim() isnt ''

    render_output_header: ->
        <ProjectSearchOutputHeader
            most_recent_path   = {@props.most_recent_path}
            command            = {@props.command}
            most_recent_search = {@props.most_recent_search}
            search_results     = {@props.search_results}
            search_error       = {@props.search_error}
            info_visible       = {@props.info_visible}
            actions            = {@props.actions} />

    render_output: ->
        if @props.search_results? or @props.search_error?
            return <ProjectSearchOutput
                most_recent_path = {@props.most_recent_path}
                results          = {@props.search_results}
                too_many_results = {@props.too_many_results}
                search_error     = {@props.search_error}
                actions          = {@props.actions} />
        else if @props.most_recent_search?
            # a search has been made but the search_results or search_error hasn't come in yet
            <Loading />

    render: ->
        <Well>
            <Row>
                <Col sm={8}>
                    <Row>
                        <Col sm={9}>
                            <ProjectSearchInput
                                user_input = {@props.user_input}
                                actions    = {@props.actions} />
                        </Col>
                        <Col sm={3}>
                            <Button bsStyle='primary' onClick={@props.actions.search} disabled={not @valid_search()}>
                                <Icon name='search' /> Search
                            </Button>
                        </Col>
                    </Row>
                    {@render_output_header() if @props.most_recent_search? and @props.most_recent_path?}
                </Col>

                <Col sm={4} style={fontSize:'16px'}>
                    <Checkbox
                        checked  = {@props.subdirectories}
                        onChange = {@props.actions.toggle_search_checkbox_subdirectories}>
                        Include subdirectories
                    </Checkbox>
                    <Checkbox
                        checked  = {@props.case_sensitive}
                        onChange = {@props.actions.toggle_search_checkbox_case_sensitive}>
                        Case sensitive search
                    </Checkbox>
                    <Checkbox
                        checked  = {@props.hidden_files}
                        onChange = {@props.actions.toggle_search_checkbox_hidden_files}>
                        Include hidden files
                    </Checkbox>
                    <Checkbox
                        checked  = {@props.git_grep}
                        onChange = {@props.actions.toggle_search_checkbox_git_grep}>
                        Only search files in GIT repo (if in a repo)
                    </Checkbox>
                </Col>
            </Row>
            <Row>
                <Col sm={12}>
                    {@render_output()}
                </Col>
            </Row>
        </Well>

ProjectSearchResultLine = rclass
    displayName : 'ProjectSearch-ProjectSearchResultLine'

    mixins: [ImmutablePureRenderMixin]

    propTypes :
        filename         : rtypes.string
        description      : rtypes.string
        line_number      : rtypes.number
        most_recent_path : rtypes.string
        actions          : rtypes.object.isRequired

    click_filename: (e) ->
        e.preventDefault()
        @props.actions.open_file
            path       : misc.path_to_file(@props.most_recent_path, @props.filename, @props.line_number)
            foreground : misc.should_open_in_foreground(e)

    render: ->
        <div style={wordWrap:'break-word'}>
            <a onClick={@click_filename} href=''><strong>{@props.filename}</strong></a>
            <span style={color:'#666'}> {@props.description}</span>
        </div>

ProjectSearchHeader = rclass ({name}) ->
    displayName : 'ProjectSearch-ProjectSearchHeader'

    mixins: [ImmutablePureRenderMixin]

    reduxProps :
        "#{name}" :
            current_path : rtypes.string

    propTypes :
        actions : rtypes.object.isRequired

    render: ->
        <h1 style={marginTop:"0px"}>
            <Icon name='search' /> Search <span className='hidden-xs'> in <PathLink path={@props.current_path} actions={@props.actions} /></span>
        </h1>

exports.ProjectSearch = rclass ({name}) ->
    displayName : 'ProjectSearch'

    render: ->
        <div style={padding:'15px'}>
            <Row>
                <Col sm={12}>
                    <ProjectSearchHeader actions={@actions(name)} name={name} />
                </Col>
            </Row>
            <Row>
                <Col sm={12}>
                    <ProjectSearchBody actions={@actions(name)} name={name} />
                </Col>
            </Row>
        </div>