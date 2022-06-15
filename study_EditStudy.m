function study = study_EditStudy(study)

newStudy = false;
if nargin < 1 || isempty(study)
    newStudy = true;
end

h = build_GUI;
h = assign_callbacks(h);

if newStudy
    study = callback_newStudy([],[],h);
    %close the figure if the study comes back empty 
    if isempty(study)
        close(h.figure);
        return
    end
end
setstudy(h,study);
populate_studyinfo(study, h);


%**************************************************************************
function study = callback_newStudy(hObject, hEvent, h)
%callback function for when user pushes the new study button
%this will also be called when the user calls this funciton without passing
%an existing study structure

EEGPath = study_GetEEGPath;

%initialize a new study structure
study.filename = [];
study.name = [];
study.description = [];
study.path = [];
study.nfactors = 0;
study.nsubjects = 0;
study.nconditions = 0;
study.history = [];
study.subject = [];


%make sure that the general tab is selected
h.infotabs.SelectedTab = h.tab_general;

%create a dialog box telling the person what is going to happen
msg ='Select the folder where the study data are located. ';
msg = [msg, 'Particpant data should be stored in individual subfolders within the folder you select'];
choice = uiconfirm(h.figure, msg,'New Study',...
    'Options',{'Proceed', 'Cancel'},...
    'CancelOption',2,...
    'DefaultOption',1,...
    'Icon', 'info');

%if they choose to proceed present them with a dialog box to select the
%path of the data
if strcmp(choice, 'Proceed')
    h.figure.Visible = false;
    studyFolder = uigetdir(EEGPath, 'Select data folder');
    h.figure.Visible = true;
    if studyFolder == 0
        study = [];
        return
    end

    %extract just the folder portion so the path is relative ot the EEGPath
    i = strfind(studyFolder, EEGPath);
    studyFolder = studyFolder(i+length(EEGPath):length(studyFolder));    
    study.path = studyFolder;
    
    %now get the channel locations file for the study
    msg = 'Select the file that contains channel location information.';
    msg = [msg, 'The same positions will be assigned to each file during conversion'];
    selection = uiconfirm(h.figure, msg, 'Add channel locations',...
            'Options', {'Add Locations', 'Cancel'}, 'Icon', 'info');
        
    if strcmp(selection, 'Add Locations')
        h.figure.Visible = false;
        [loc_file, loc_path] = uigetfile('*.*', 'Select channel locations file');
        h.figure.Visible = true;
        if ~isempty(loc_file)
            %use the eeglab readlocs function to get the position
            %information
            chanlocs = readlocs(fullfile(loc_path,loc_file));
            if ~isempty(chanlocs)
                study.chanlocs = chanlocs;
            end
        end
    else
        study = [];
        return
    end

    %now get the channel locations file for the study
    msg = 'Would you like to try and autodetect the subject folders for this experiment?';
    msg = [msg, 'If you select NO you can add subjets manually using the Subjects tab.'];
    selection = uiconfirm(h.figure, msg, 'Add channel locations',...
            'Options', {'Yes', 'No'}, 'Icon', 'question');
        
    if strcmp(selection, 'Yes')
        study = autoAssignSubjects(study);
    end
    
    setstudy(h, study);
    %save the study
    [study, notsaved_flag] = study_SaveStudy(study, 'saveas', true);
    if notsaved_flag
        study = [];
        return
    end

end

%************************************************************************
%helper functions
function populate_studyinfo(study, h)

h.edit_studyname.Value = study.name;
h.edit_studypath.Value = study.path;
if isempty(study.description)
    h.edit_studydescr.Value = '';
else
    h.edit_studydescr.Value = study.description;
end
populate_SubjectDisplay(study, h)
populate_ChanGroupDisplay(study, h)
populate_bintree(study, h)

%*************************************************************************
function populate_SubjectDisplay(study, h)

%clear the nodes from the tree
n = h.tree_subjectlist.Children;
delete(n);
if study.nsubjects > 0

    badSubjStyle = uistyle('FontColor', 'r');

    for ss = 1:length(study.subject)
        n = uitreenode('Parent', h.tree_subjectlist,...
            'Text', sprintf('Subject: \t%s', study.subject(ss).ID),...
            'NodeData', ss);
        if strcmp(study.subject(ss).status, 'bad')
            addStyle(h.tree_subjectlist, badSubjStyle, 'node', n);
        end
        uitreenode('Parent', n,...
            'Text', sprintf('Data path:\t\t%s', study.subject(ss).path),...
            'NodeData', ss);
        uitreenode('Parent', n,...
            'Text', sprintf('Gender:\t\t\t%s', study.subject(ss).gender),...
            'NodeData', ss);
        uitreenode('Parent', n,...
            'Text', sprintf('Handedness:\t\t%s', study.subject(ss).hand),...
            'NodeData', ss);
        uitreenode('Parent', n,...
            'Text', sprintf('Age:\t\t\t\t%s', study.subject(ss).age),...
            'NodeData', ss);
        uitreenode('Parent', n,...
            'Text', sprintf('Status:\t\t\t%s', study.subject(ss).status),...
            'NodeData', ss);
    end
end
%**************************************************************************
function populate_ChanGroupDisplay(study, h)

n = h.tree_changroup.Children;
n.delete;

if ~isfield(study, 'chanlocs')
    return
end

h.list_chanpicker.Items = {study.chanlocs.labels};
h.list_chanpicker.ItemsData = 1:length(study.chanlocs);
callback_drawchannelpositions([],[], h)

%delete existing channel groups in the display

%add the ones from thh current study

if isfield(study,'chgroups')
    for ii = 1:length(study.chgroups)
        n = uitreenode('Parent', h.tree_changroup,...
            'Text', study.chgroups(ii).name, 'NodeData', ii);
        for jj = 1:length(study.chgroups(ii).chans)
            uitreenode('Parent', n, 'Text', study.chgroups(ii).chanlocs(jj).labels,...
                'NodeData', ii);
        end
    end
end

%*************************************************************************
%draw the display that shows the channel locations on a 2-d projection
%**************************************************************************
function callback_drawchannelpositions(hobject, eventdata, h)

study = getstudy(h);

selchans = h.list_chanpicker.Value;

[mHandle, smHandle] = wwu_PlotChannelLocations(study.chanlocs,...
    'Elec_Color', h.p.buttoncolor,...
    'Elec_Selcolor',[.2,.9,.2],...
    'Elec_Size', 50,...
    'Elec_SelSize', 150,...
    'Labels', 'name',...
    'Subset', selchans,...
    'AxisHandle', h.axis_chanpicker);

mHandle.ButtonDownFcn = {@callback_channelClick, h};
smHandle.ButtonDownFcn = {@callback_channelClick, h};

%************************************************************************
function callback_channelClick(hObject, ~, h)

  study = getstudy(h);

  [yp, xp] =  wwu_ChannelProjection(study.chanlocs);


  mp = h.axis_chanpicker.CurrentPoint;
  x = mp(1,1); y = mp(1,2);
  %get the cartesian distance to all the electrodes
  dx = xp - x; dy = yp - y;
  d = sqrt(dx.^2 + dy.^2);

  %the smallest is the one that was clicked
  [~, en] = min(d);
  i = find(h.list_chanpicker.Value==en);
  if isempty(i)
      h.list_chanpicker.Value = sort([h.list_chanpicker.Value, en]);
  else
      h.list_chanpicker.Value(i) = [];
  end
  
  callback_drawchannelpositions(hObject, [], h)

function callback_handleMouseDown(hObject, hEvent, h)
    

    if contains(hObject.SelectionType, 'extend')
        cp = hObject.CurrentPoint;
        ap = h.axis_chanpicker.Position;
        pp = h.infotabs.Position;

        xp = cp(1,1); yp = cp(1,2);
        axWin(1) = ap(1) + pp(1);
        axWin(2) = ap(2) + pp(2);
        axWin(3) = axWin(1) + ap(3);
        axWin(4) = axWin(2) + ap(4);

        isInAxis = (xp > axWin(1)) && (yp > axWin(2)) && (xp < axWin(3)) && (yp < axWin(4));
        if isInAxis
            css = h.axis_chanpicker.UserData;
            css.drawing = true;
            %initialize drawing
            cp = h.axis_chanpicker.CurrentPoint;
            css.line = line(h.axis_chanpicker, cp(1,1), cp(1,2), 'Color', 'g',...
                'LineWidth', 2);
            h.axis_chanpicker.UserData = css;
            fprintf('started drawing...')
        end
    end

%*************************************************************************        
function callback_handleMouseUp(hObject, hEvent, h)
    
    css = h.axis_chanpicker.UserData;
    if isempty(css) || css.drawing == false
        return
    else
        %delete the line object
        %close the shape
        css.line.XData(end+1) = css.line.XData(1);
        css.line.YData(end+1) = css.line.YData(1);
        drawnow
  
        %figure out which channels are in the shape
        study = getstudy(h);
        [yp, xp] = wwu_ChannelProjection(study.chanlocs);
        selected = find(inpolygon(xp, yp, css.line.XData, css.line.YData));
        h.list_chanpicker.Value = selected;
        callback_drawchannelpositions(hObject, hEvent, h);

        %clear the drawing and stop drawing mode
        css.drawing = false;
        h.axis_chanpicker.UserData = css;
        fprintf('finished drawing\n');
        delete(css.line);
        

    end
%************************************************************************
function callback_handleMouseMove(hObject, hEvent, h)

    css = h.axis_chanpicker.UserData;
    if ~isempty(css) && css.drawing == true
        %the handle may get deleted
        if ~isvalid(css.line)
            css.drawing = false;
            h.axis_chanpicker.UserData  = css;
            return
        end

        cp = h.axis_chanpicker.CurrentPoint;
        css.line.XData(end+1) = cp(1,1);
        css.line.YData(end+1) = cp(1,2);
        drawnow;
    end

    

%*************************************************************************
%edit the description of the study in real time
function callback_editstudydescr(hObject, event, h)

study = getstudy(h);
study.description = h.edit_studydescr.Value;
study = study_SaveStudy(study);
setstudy(h,study);
%*************************************************************************
%**************************************************************************
function callback_addbingroup(hObject, hEvent, h)


study = getstudy(h);

epochgroup_name = h.edit_bingroupname.Value;
epochgroup_filename  = h.edit_epochfilename.Value;
epoch_start = h.edit_epochstart.Value;
epoch_end = h.edit_epochend.Value;

isNew = hObject.UserData;

if isempty(epochgroup_name)
    uialert(h.figure, 'Please enter a valid bin group name.', 'Error');
    return
else
    eg.name = epochgroup_name;
end

if isempty(epochgroup_filename)
    uialert(h.figure, 'Please enter a valid bin group file name.', 'Error');
    return
else
    eg.filename = epochgroup_filename;
end

    
if epoch_start >= epoch_end
    uialert(h.figure, 'the epoch start cannot be greater than the epoch end.', 'Error');
else
    eg.interval = [epoch_start, epoch_end];
end


if ~isNew %this is an update and not a new bin group
   n = h.tree_bingrouplist.SelectedNodes;
   cnum = n.NodeData{1};
   eg.bins = study.bingroup(cnum).bins; %save the bin information
elseif ~isfield(study, 'bingroup')
    cnum = 1;   
    eg.bins = [];
else
    cnum = length(study.bingroup) + 1;
    eg.bins = [];
end

study.bingroup(cnum)  = eg;

study = study_SaveStudy(study);
setstudy(h,study);
populate_bintree(study, h);

%witch back to the non-editing mode now
callback_changeBinGroupEditStatus(hObject, hEvent, h, false)



%*************************************************************************
function callback_removebingroup(hObject, eventdata, h)

n = h.tree_bingrouplist.SelectedNodes;
study = getstudy(h);


if isempty(n)
    uialert(h.figure, 'Try selecting something to delete first.', 'Epoch delete');
    return
end

enum = n.NodeData{1};
cnum = n.NodeData{2};

if cnum==0 % this is an epoch group
    response = uiconfirm(h.figure, 'Are you sure you want to delete this Bin Group and all its associated bin information?', 'Delete Bin Group');
    if contains(response, 'OK')
        study.bingroup(enum) = [];
        enum = 0;
    end
else
    response = uiconfirm(h.figure, 'Are you sure you want to delete this Bin?', 'Delete Bin');
    if contains(response, 'OK')
        study.bingroup(enum).bins(cnum) = [];
        cnum = length(study.bingroup(enum).bins);
    end
end

study = study_SaveStudy(study);
setstudy(h,study);
populate_bintree(study, h, [enum, cnum]);    

%*************************************************************************
%callback function for allowing editing of an existing condition
function callback_editbingroup(hObject, eventdata, h, isNew)

study = getstudy(h);
n = h.tree_bingrouplist.SelectedNodes;
if isNew
    h.edit_bingroupname.Value = '';
    h.edit_epochfilename.Value = '';
    h.edit_epochstart.Value = '';
    h.edit_epochend.Value = '';
else
    if isempty(n)
        uialert(h.figure, 'You must select a Bin Group to edit.', 'Edit Bin Group');
        return
    end

    gnum = n.NodeData{1};
    
    h.edit_bingroupname.Value = study.bingroup(gnum).name;
    h.edit_epochfilename.Value = study.bingroup(gnum).filename;
    h.edit_epochstart.Value = study.bingroup(gnum).interval(1);
    h.edit_epochend.Value = study.bingroup(gnum).interval(2);
    
end

%pass the isNew flag forward to the update button so the 
%add bin function knows whether to update or add.
h.button_bingroupupdate.UserData = isNew;
callback_changeBinGroupEditStatus(hObject, eventdata, h, true)

%*************************************************************************
function callback_changeBinGroupEditStatus(hObject, hEvent, h, editing)
    
    h.button_bingroupadd.Enable = ~editing;
    h.button_bingroupremove.Enable = ~editing;
    h.button_bingroupedit.Enable = ~editing;
   
    h.tree_bingrouplist.Enable = ~editing;

    if editing
         h.panel_bingroup.Enable = 'on';
    else
         h.panel_bingroup.Enable = 'off';
    end
  

%*************************************************************************
%adds a new condition to an Epoch group or adds edited information to an
%existing group.
function callback_addbintogroup(hObject,eventdata, h)

study = getstudy(h);


n = h.tree_bingrouplist.SelectedNodes;
if isempty(n)
    uialert(h.figure,'Please create or select a Bin Group first.', 'Add Condition');
    return
end

ndata = n.NodeData;
gnum = ndata{1}; cnum = ndata{2};

if ~isempty(study.bingroup(gnum).bins)
    new_cnum = length(study.bingroup(gnum).bins) + 1;
else
    new_cnum = 1;
end

%get information from the input boxes
p.name = h.edit_binname.Value;
p.events = h.edit_eventlist.Value;


%do some checking
if strcmp(p.name, '')
    uialert(h.figure,'Please enter a valid Bin Name', 'Add Bin');
    return
end

if isempty(p.events)
    uialert(h.figure,'Please enter some event markers', 'Add Condition');
    return
end

if new_cnum==1
    study.bingroup(gnum).bins = p;
else
    study.bingroup(gnum).bins(new_cnum) = p;
end


study = study_SaveStudy(study);
setstudy(h,study);
populate_bintree(study, h, [gnum, new_cnum]);

%***************************************************************************
%this fills the epoch tree information list with the current epoch
%information for the loaded study
function populate_bintree(study, h, select)

if nargin < 3
    select = [0,0];
end
%clear existing nodes
n = h.tree_bingrouplist.Children;
n.delete;

if ~isfield(study, 'bingroup')
    return
end

node_to_select = [];

for ii = 1:length(study.bingroup)
    n = uitreenode('Parent', h.tree_bingrouplist,'Text', study.bingroup(ii).name,'NodeData', {ii, 0}, 'ContextMenu',h.cm_epochlist);
    uitreenode('Parent', n, 'Text', sprintf('start:\t%0.3g', study.bingroup(ii).interval(1)),...
                'NodeData', {ii, 0}, 'ContextMenu',h.cm_epochlist);
    uitreenode('Parent', n, 'Text', sprintf('end:\t\t%0.3g', study.bingroup(ii).interval(2)),...
                'NodeData', {ii, 0}, 'ContextMenu',h.cm_epochlist);
    n2 = uitreenode('Parent', n, 'Text', 'bins',...
                'NodeData', {ii, 0}, 'ContextMenu',h.cm_epochlist);
                    
    if isfield(study.bingroup(ii), 'bins')
        for jj = 1:length(study.bingroup(ii).bins)      
            n3 = uitreenode('Parent', n2, 'Text', sprintf('%i:\t%s',jj, study.bingroup(ii).bins(jj).name),...
                'NodeData', {ii, jj}, 'ContextMenu',h.cm_epochlist);
            uitreenode('Parent', n3, 'Text', sprintf('bin events:\t%s ', study.bingroup(ii).bins(jj).events{:}),...
                'NodeData', {ii, jj}, 'ContextMenu',h.cm_epochlist);
            if (ii==select(1)) && (jj==select(2))
                node_to_select = n3;
            end
                      
        end
    end
  
end
if ~isempty(node_to_select)
    expand(node_to_select.Parent);
    h.tree_bingrouplist.SelectedNodes = node_to_select;
end

%*************************************************************************
%this is the callback for the Create button on the channel group tab
%*************************************************************************
function callback_createchangroup(hObject, eventdata,h)

study = getstudy(h);

if ~isfield(study, 'chgroups')
    default_groupname = 'Group 1';
    gnum = 1;
else
    default_groupname = sprintf('Group %i', sum(contains({study.chgroups.name},'Group'))+1);
    gnum = length(study.chgroups) + 1;
end

%get a name for this group
prompt = {'Enter a name for the channel group'};
dlgtitle = 'New Channel Group';
dims = [1 35];
definput = {default_groupname};
answer = inputdlg(prompt,dlgtitle,dims,definput);

%now make the group

study.chgroups(gnum).name = answer{:};
study.chgroups(gnum).chans = h.list_chanpicker.Value;
study.chgroups(gnum).chanlocs = study.chanlocs(study.chgroups(gnum).chans);

setstudy(h, study);
study = study_SaveStudy(study);
populate_ChanGroupDisplay(study, h)

%*************************************************************************
function callback_removechangroup(hObject, eventdata, h)

study = getstudy(h);
n = h.tree_changroup.SelectedNodes;

if isempty(n)
    return
end

msg = sprintf('Are you sure you want to remove channgel group %s', study.chgroups(n.NodeData).name);

if strcmp(uiconfirm(h.figure, msg, 'Remove Channel Group'), 'OK')
    
    study.chgroups(n.NodeData) = [];
    
    setstudy( h, study)
    study_SaveStudy(study);
    populate_ChanGroupDisplay(study, h)
    
end

%**************************************************************************
%function to select the channels based on the channel group the user
%selects
%**************************************************************************
function callback_selectchangroup(hObject, eventdata, h)

study = getstudy(h);
n = h.tree_changroup.SelectedNodes;

if isempty(n)
    return
end
h.list_chanpicker.Value = study.chgroups(n.NodeData).chans;
callback_drawchannelpositions(hObject,eventdata,h)

%*********************************************************************
function callback_editsubject(hObject, hEvent,h, isNew)

study = getstudy(h);
if ~isNew
    n = h.tree_subjectlist.SelectedNodes;
    if isempty(n)
        uialert(h.figure, 'Please select a subject to edit', 'Subject Edit');
        return
    end
    
    sn = n.NodeData;
    
    
    %place the values from the selected subject in the appropriate controls
    h.edit_subjectid.Value = study.subject(sn).ID;
    h.edit_subjectpath.Value = study.subject(sn).path;
    h.dropdown_subjectgender.Value = study.subject(sn).gender;
    h.spinner_subjectage.Value = str2double(study.subject(sn).age);
    h.dropdown_subjecthand.Value = study.subject(sn).hand;
    h.check_subjectstatus.Value = strcmp(study.subject(sn).status, 'good');
    
    h.button_updatesubject.UserData = sn;

else
    set_subjectdefaults(h);
end

%change the status of the controls so the user cannot 
%do anything until they finish editing the subject
callback_changeSubjectEntryMode(hObject, hEvent, h, false);

%**************************************************************************
%add a subject to the current study
function callback_addsubject(hObject, hEvent, h)

sn = hObject.UserData;
study = getstudy(h);

%collect all the data into a subject structure
subject.ID = h.edit_subjectid.Value;
subject.path = h.edit_subjectpath.Value;
subject.gender = h.dropdown_subjectgender.Value;
subject.age = num2str(h.spinner_subjectage.Value);
subject.hand = h.dropdown_subjecthand.Value;
if h.check_subjectstatus.Value==1
    subject.status =  'good';
else
    subject.status = 'bad';
end

%make sure all the necessary information is included
if isempty(subject.ID) || isempty(subject.path)
    uialert(h.figure, 'Please include a valid Subject ID and Folder.', 'New Subject');
    return
end

%make sure the path actually exists.
fullpath = fullfile(study_GetEEGPath, study.path, subject.path);
if ~isfolder(fullpath)
    uialert(h.figure, 'The subject folder could not be found. The subject folder must reside in the study folder.', 'New Subject');
    return
end

if ~isempty(sn)   %this is the edit mode
    study.subject(sn) = subject;
    %change the status of the controls so the user cannot 
    %do anything until they finish editing the subject
    callback_changeSubjectEntryMode(hObject, hEvent, h, true);
    
else
    if ~isfield(study, 'subject') 
        study.subject = subject;
    else
        if isempty(study.subject)
            study.subject = subject;
        else
            study.subject(end+1) = subject;
        end
    end
    study.nsubjects = study.nsubjects + 1;
end

%reset all the values to their default state
set_subjectdefaults(h);

%save the study within the figure
setstudy( h, study);

%save the study on the disk
study_SaveStudy(study);

%refresh the node tree
populate_SubjectDisplay(study, h);

%*************************************************************************
function callback_changeSubjectEntryMode(hObject, hEvent, h, state)

    h.button_subjectadd.Enable = state;
    h.button_subjectremove.Enable = state;
    h.button_subjectedit.Enable = state;
    h.tree_subjectlist.Enable = state;
    
    if state
        h.panel_sbj.Enable = 'off';
    else
        h.panel_sbj.Enable = 'on';
    end

%*************************************************************************
function callback_removesubject(hObject, event, h)

sn = hObject.UserData;
study = getstudy(h);

if ~isempty(sn)   %this is the cancel mode
    
    h.button_subjectadd.Text = 'Add';
    h.button_subjectadd.UserData = [];
    h.button_subjectremove.Text = 'Remove';
    h.button_subjectremove.UserData = [];
    h.button_subjectedit.Enable = 'on';
    
else
    n = h.tree_subjectlist.SelectedNodes;
    if isempty(n)
        uialert(h.figure, 'Please select a subject to edit', 'Subject Edit');
        return
    end
    
    sn = n.NodeData;
    msgstr = sprintf('Are you sure you want to remove subject %s from this study?',...
        study.subject(sn).ID);
    selection = uiconfirm(h.figure, msgstr, 'Remove Subject',...
        'Options', {'Remove', 'Cancel'},...
        'DefaultOption', 2,...
        'CancelOption', 2);
    if strcmp(selection, 'Remove')
        study.subject(sn) = [];
        study.nsubjects = study.nsubjects -1;
        
        %save the study within the figure
        setstudy(h, study);
        
        %save the study on the disk
        study_SaveStudy(study);
        
        %refresh the node tree
        populate_studyinfo(study, h);
    end
    
    
end
set_subjectdefaults(h);

%*************************************************************************
function callback_getsubjectpath(hObject, eventdata, h)

eeg_path = study_GetEEGPath();


study = getstudy(h);

%build the path for this study
fullstudypath = wwu_buildpath(eeg_path, study.path);

%get the user path input
h.figure.Visible = false;
path = uigetdir(fullstudypath);
h.figure.Visible = true;

%make sure they made a choice and did not cancel
if isempty(path); return; end

%make sure the folder is in the study folder
i = strfind(path, fullstudypath);
if ~isempty(i)
    %get just the relative portion
    path = path(i+length(fullstudypath):length(path));
else
    uialert(h.figure, sprintf('Not a valid folder.  Subject data folder must be located within the study folder %s',...
        fullstudypath), 'try it again...','Icon', 'info');
    return
end

%assign it
h.edit_subjectpath.Value = path;

%automatically create a likely subject ID if the field is blank
if isempty(h.edit_subjectid.Value)
    [~, autoID, ~] = fileparts(path);
    h.edit_subjectid.Value = autoID;
end


%*************************************************************************
%these are the defaults for adding a new subject
%*************************************************************************
function set_subjectdefaults(h)

    h.edit_subjectid.Value = '';
    h.edit_subjectpath.Value = '';
    h.dropdown_subjectgender.Value = 'female';
    h.dropdown_subjecthand.Value = 'right';
    h.spinner_subjectage.Value = 20;
    h.check_subjectstatus.Value = 1;

%******************************************************************
function callback_changeStudyName(hObject, hEvent, h)

    study = getstudy(h);

    newName = h.edit_studyname.Value;
    if ~isempty(newName)
        study.name = newName;
        study = study_SaveStudy(study);
    end

    fprintf('saving changes to study name\n');
    setstudy(h, study);
%*****************************************************************
function study = autoAssignSubjects(study)

eeg_path = study_GetEEGPath();

%build the path for this study
studypath = wwu_buildpath(eeg_path, study.path);
d = dir(studypath); 
d = d([d.isdir]);  %eliminate any that arent folders
folderNames = {d.name};

%find all folders that start with a letters and are followed by numbers
%anything with a space will be removed.
expr = '[a-zA-Z]+\d+';
r = regexp(folderNames, expr);  %search for the desired string

for ii = 1:length(r)
    if r{ii} == 1
        subject.ID = folderNames{ii};
        subject.path = [filesep, folderNames{ii}];
        subject.gender = 'female';
        subject.age = 20;
        subject.hand = 'right';
        subject.status = true;
        if ~isfield(study, 'subject')
            study.subject(1) = subject;
        else
            if isempty(study.subject)
                study.subject = subject;
            else
                study.subject(end+1) = subject;
            end
        end
        study.nsubjects = study.nsubjects + 1;
    end
end

function study = getstudy(h)
    study = h.figure.UserData;

function setstudy(h, study)
    h.figure.UserData = study;
%**************************************************************************
function h = assign_callbacks(h)
%a function that assigns all of the control callback functions
%I separate these out because it is easier to deal with the creation of the
%objects and the assignment of the callbacks in two smaller callbacks
%rather than one large one.

    h.figure.WindowButtonUpFcn = {@callback_handleMouseUp, h};
    h.figure.WindowButtonDownFcn = {@callback_handleMouseDown, h};
    h.figure.WindowButtonMotionFcn = {@callback_handleMouseMove, h};
    
    h.edit_studyname.ValueChangedFcn = {@callback_changeStudyName, h};
    h.edit_studydescr.ValueChangedFcn = {@callback_editstudydescr, h};

    h.button_subjectedit.ButtonPushedFcn = {@callback_editsubject, h, false};
    h.button_subjectadd.ButtonPushedFcn =  {@callback_editsubject, h, true};
    h.button_subjectpath.ButtonPushedFcn = {@callback_getsubjectpath, h};
    h.button_updatesubject.ButtonPushedFcn = {@callback_addsubject, h};
    h.button_cancelsubject.ButtonPushedFcn = {@callback_changeSubjectEntryMode, h, true};
    h.button_subjectremove.ButtonPushedFcn = {@callback_removesubject, h};

    h.button_bingroupupdate.ButtonPushedFcn = {@callback_addbingroup, h};
    h.button_addbin.ButtonPushedFcn = {@callback_addbintogroup, h};
    h.button_bingroupremove.ButtonPushedFcn = {@callback_removebingroup, h};
    h.button_bingroupadd.ButtonPushedFcn = {@callback_editbingroup, h, true};
    h.button_bingroupedit.ButtonPushedFcn = {@callback_editbingroup, h, false};
    h.list_binevents.ValueChangedFcn = {@callback_addtoeventlist, h};
    h.button_bingroupcancel.ButtonPushedFcn = {@callback_changeBinGroupEditStatus, h, false};

    h.button_addchangroup.ButtonPushedFcn  = {@callback_createchangroup, h};
    h.button_removechangroup.ButtonPushedFcn = {@callback_removechangroup, h};
    h.tree_changroup.SelectionChangedFcn = {@callback_selectchangroup, h};
    h.list_chanpicker.ValueChangedFcn = {@callback_drawchannelpositions, h};
  
%**************************************************************************
function h = build_GUI()

screenSize = get(0, 'ScreenSize');
p = plot_params;
h.p = p;
width = 780;
height = 400;
left = (screenSize(3) -width)/2;
bottom = (screenSize(4) - height)/3;
h.figure = uifigure('Position', [left,bottom,width,height]);
%h.figure.WindowStyle = 'alwaysontop';
h.figure.Resize = false;
h.figure.Name = 'Edit Study';
h.figureNumberTitle = false;

%main buttons
x = width - 10 - p.buttonwidth;

h.btn_return = uibutton('Parent', h.figure,...
    'Position', [x, 10, p.buttonwidth, p.buttonheight],...
    'BackgroundColor', p.buttoncolor,...
    'Text', 'Return',...
    'FontColor', p.buttonfontcolor);

h.btn_newstudy = uibutton('Parent', h.figure,...
    'Position', [x-10-p.buttonwidth, 10, p.buttonwidth, p.buttonheight],...
    'BackgroundColor', p.buttoncolor,...
    'Text', 'New',...
    'FontColor', p.buttonfontcolor);

h.infotabs = uitabgroup(...
    'Parent',h.figure,...
    'TabLocation', 'top',...
    'Position', [10,40,width-20,height-50]...
    );


%general tab
h.tab_general = uitab(...
    'Parent', h.infotabs,...
    'Title', 'General',...
    'BackgroundColor', p.backcolor);

uilabel('Parent', h.tab_general,...
    'Text', 'Study name',...
    'Position', [10, 280,100,25],...
    'Fontcolor', p.labelfontcolor);

h.edit_studyname = uieditfield(...
    'Parent', h.tab_general,...
    'Placeholder','click "Edit Name" to enter a study name',...
    'Value', '',...
    'Position', [10,255,250,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

uilabel('Parent', h.tab_general,...
    'Text', 'Data location',...
    'Position', [400, 280,100,25],...
    'Fontcolor', p.labelfontcolor);

h.edit_studypath = uieditfield(...
    'Parent', h.tab_general,...
    'Placeholder','click "Edit Path" to enter a data path',...
    'Editable','off',...
    'Value', '',...
    'Position', [400,255,250,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

h.btn_editpath = uibutton( 'Parent', h.tab_general,...
    'Text', 'Edit Path',...
    'Position', [660,255,p.buttonwidth,p.buttonheight],...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

uilabel('Parent', h.tab_general,...
    'Text', 'Experiment Description',...
    'Position', [10, 220,200,25],...
    'Fontcolor', p.labelfontcolor);

h.edit_studydescr = uitextarea(...
    'Parent', h.tab_general,...
    'Placeholder','Enter your description here',...
    'Value', '',...
    'Position', [10,60,725,160],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);




%*************************************************************************
%subject panel
h.tab_subjects = uitab(...
    'Parent', h.infotabs,...
    'Title', 'Subjects');


h.panel_sbj = uipanel('Parent', h.tab_subjects,...
    'Position', [320, 10, 400, 300],...
    'Title', 'Subject Properties',...
    'Enable','off',...
    'BackgroundColor',p.backcolor);

rc = 20;
t = 245;

uilabel('Parent', h.panel_sbj,...
    'Text', 'Subject ID',...
    'Position', [rc, t-40,100,25],...
    'Fontcolor', p.labelfontcolor);

uilabel('Parent', h.panel_sbj,...
    'Text', 'Subject Folder',...
    'Position', [rc, t,100,25],...
    'Fontcolor', p.labelfontcolor);

uilabel('Parent',h.panel_sbj,...
    'Text', 'Gender',...
    'Position', [rc, t-80,100,25],...
    'Fontcolor', p.labelfontcolor);

uilabel('Parent', h.panel_sbj,...
    'Text', 'Age',...
    'Position', [rc, t-120,50,25],...
    'Fontcolor', p.labelfontcolor);

uilabel('Parent',h.panel_sbj,...
    'Text', 'Handedness',...
    'Position', [rc, t-160,100,25],...
    'Fontcolor', p.labelfontcolor);

h.edit_subjectid = uieditfield(...
    'Parent', h.panel_sbj,...
    'Value', '',...
    'Position', [rc+90,t-40,140,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

h.edit_subjectpath = uieditfield(...
    'Parent',h.panel_sbj,...
    'Value', '',...
    'Position', [rc+90,t,140,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

h.button_subjectpath = uibutton(...
    'Parent', h.panel_sbj,...
    'Text', '...', ...
    'Position', [rc+240, t, 40, 25],...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor,...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

h.dropdown_subjectgender = uidropdown(...
    'Parent',h.panel_sbj,...
    'Items', {'female', 'male', 'other'},...
    'Position', [rc+90,t-80,100,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

h.spinner_subjectage = uispinner(...
    'Parent', h.panel_sbj,...
    'Value', 20,...
    'Limits', [1,100],...
    'RoundFractionalValues', 'on',...
    'Position', [rc+90,t-120,100,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

h.dropdown_subjecthand = uidropdown(...
    'Parent', h.panel_sbj,...
    'Items', {'right', 'left', 'both'},...
    'Position', [rc+90,t-160,100,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

h.check_subjectstatus = uicheckbox(...
    'Parent', h.panel_sbj,...
    'Position', [rc, t-200, 150,25],...
    'Text', 'Good Subject',...
    'Value', true,...
    'FontColor', p.textfieldfontcolor);

h.button_updatesubject = uibutton(...
    'Parent', h.panel_sbj,...
    'Position', [310, 10, 80, 25],...
    'Text', 'Update',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

h.button_cancelsubject = uibutton(...
    'Parent', h.panel_sbj,...
    'Position', [220, 10, 80, 25],...
    'Text', 'Cancel',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

uilabel('Parent',h.tab_subjects,...
    'Position',[10,300,100,20],...
    'Text','Subject list');

h.tree_subjectlist = uitree(...
    'Parent', h.tab_subjects,...
    'Position', [10,40,260,255],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

h.button_subjectadd = uibutton(...
    'Parent', h.tab_subjects,...
    'Position', [10, 10, 80, 25],...
    'Text', 'New',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

h.button_subjectremove = uibutton(...
    'Parent', h.tab_subjects,...
    'Position', [100, 10, 80, 25],...
    'Text', 'Remove',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

h.button_subjectedit = uibutton(...
    'Parent', h.tab_subjects,...
    'Position', [190, 10, 80, 25],...
    'Text', 'Edit',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);



%*************************************************************************
% Bin tab
h.tab_bins = uitab(...
    'Parent', h.infotabs,...
    'Title', 'Bin Data',...
    'BackgroundColor', p.backcolor);

h.tree_bingrouplist = uitree(...
    'Parent', h.tab_bins,...
    'Position', [10,40,280,255],...
    'Multiselect', 'off',...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

uilabel('Parent',h.tab_bins,...
    'Position', [10,300,100,20],...
    'Text','Bin groups');

h.button_bingroupadd = uibutton(...
    'Parent', h.tab_bins,...
    'Position', [10, 10, 80, 25],...
    'Text', 'New',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

h.button_bingroupremove = uibutton(...
    'Parent', h.tab_bins,...
    'Position', [95, 10, 80, 25],...
    'Text', 'Remove',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

h.button_bingroupedit = uibutton(...
    'Parent', h.tab_bins,...
    'Position', [180, 10, 80, 25],...
    'Text', 'Edit',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

h.panel_bingroup = uipanel(...
    'Parent', h.tab_bins,...
    'Position', [360, 140, 380, 170],...
    'Title', 'Bin Group Information',...
    'Enable', 'off', ...
    'BackgroundColor', p.backcolor);

h.button_bingroupupdate = uibutton(...
    'Parent', h.panel_bingroup,...
    'Position', [290, 40, 80, 25],...
    'Text', 'Update',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

h.button_bingroupcancel = uibutton(...
    'Parent', h.panel_bingroup,...
    'Position', [290, 10, 80, 25],...
    'Text', 'Cancel',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

uilabel('Parent', h.panel_bingroup, ...
    'Position', [10, 115, 100, 25],...
    'FontColor', p.labelfontcolor, ...
    'Text', 'Bin Group Name');

uilabel('Parent', h.panel_bingroup, ...
    'Position', [10 80, 100, 25],...
    'FontColor', p.labelfontcolor, ...
    'Text', 'Epoch Filename');

uilabel('Parent', h.panel_bingroup, ...
    'Position', [10 45, 100, 25],...
    'FontColor', p.labelfontcolor, ...
    'Text', 'Epoch start');

uilabel('Parent', h.panel_bingroup, ...
    'Position', [10 10, 100, 25],...
    'FontColor', p.labelfontcolor, ...
    'Text', 'Epoch end');

h.edit_bingroupname = uieditfield(...,
    'Parent', h.panel_bingroup,...
    'Position', [120, 115, 157, 25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

h.edit_epochfilename = uieditfield(...,
    'Parent', h.panel_bingroup,...
    'Position', [120, 80, 157, 25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

h.edit_epochstart = uieditfield(...,
    'numeric',...
    'Parent', h.panel_bingroup,...
    'Position', [120, 45, 75, 25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'ValueDisplayFormat', '%0.3g sec.',...
    'Value', -.1);

h.edit_epochend = uieditfield(...,
    'numeric',...
    'Parent', h.panel_bingroup,...
    'Position', [120, 10, 75, 25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'ValueDisplayFormat', '%0.3g sec.',...
    'Value', .5);

h.panel_bin = uipanel(...
    'Parent', h.tab_bins,...
    'Position', [360, 5, 380, 130],...
    'Title', 'Bin Information',...
    'BackgroundColor', p.backcolor);


uilabel('Parent', h.panel_bin, ...
    'Position', [10 80,100, 25],...
    'FontColor', p.labelfontcolor, ...
    'Text', 'Bin Name');

uilabel('Parent', h.panel_bin, ...
    'Position', [10 50, 100, 25],...
    'FontColor', p.labelfontcolor, ...
    'Text', 'Bin Events');

h.edit_binname = uieditfield(...,
    'Parent', h.panel_bin,...
    'Position', [120, 80, 157, 25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

h.edit_eventlist = uitextarea(...,
    'Parent', h.panel_bin,...
    'Position', [120, 10, 157, 55],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

h.button_addbin = uibutton(...
    'Parent', h.panel_bin, ...
    'Position', [290, 80, 80, 25],...
    'Text', 'Add', ...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor,...
    'UserData', 0);

%*************************************************************************
%channel group tab
h.tab_changroup = uitab(...
    'Parent', h.infotabs,...
    'Title', 'Channel Group',...
    'BackgroundColor', p.backcolor,...
    'Tag', 'changroup');

h.axis_chanpicker = uiaxes(...
    'Parent', h.tab_changroup,...
    'Position', [210,0,450,330],...
    'XTick', [], 'YTick', [],...
    'BackgroundColor', p.backcolor,...
    'Color', p.backcolor,...
    'XColor', p.backcolor,...
    'YColor', p.backcolor);
h.axis_chanpicker.Toolbar.Visible = 'off';
h.axis_chanpicker.Interactions = [];
h.axis_chanpicker.PlotBoxAspectRatio = [1,1,1];
h.axis_chanpicker.PlotBoxAspectRatioMode = 'manual';

h.list_chanpicker = uilistbox(...
    'Parent', h.tab_changroup,...
    'Position', [662, 10, 85, 285],...
    'Multiselect', 'on',...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

uilabel('Parent', h.tab_changroup,...
    'Position', [662,300,100,20],...
    'Text', 'Channel list',...
    'Fontcolor', p.labelfontcolor);

h.tree_changroup = uitree(...
    'Parent', h.tab_changroup,...
    'Position', [10,40,200,245],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

uilabel('Parent', h.tab_changroup,...
    'Position', [10,300,100,20],...
    'Text', 'Channel Groups',...
    'Fontcolor', p.labelfontcolor);

h.button_addchangroup = uibutton(...
    'Parent', h.tab_changroup,...
    'Position', [10,10,90,25],...
    'Text', 'Create',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

h.button_removechangroup = uibutton(...
    'Parent', h.tab_changroup,...
    'Position', [110,10,90,25],...
    'Text', 'Remove ',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

%Context menus
h.cm_epochlist = uicontextmenu(h.figure);

uimenu(h.cm_epochlist, 'Text', 'Edit', 'MenuSelectedFcn', {@callback_editbingroup, h});
uimenu(h.cm_epochlist, 'Text', 'Delete', 'MenuSelectedFcn', {@callback_removebingroup, h});