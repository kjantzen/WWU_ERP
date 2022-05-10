function study_PlotEPC(study, filenames)

%build the figure
p = plot_params;


if p.screenwidth < 1000 
    W = round(p.screenwdith); H = round(p.screenheight);
else   
    W = round(p.screenwidth * .5); H = round(p.screenheight * .6);
end

figpos = [(p.screenwidth - W)/2, (p.screenheight - H)/2, W, H];

%create the figure
handles.figure = uifigure(...
    'Color', p.backcolor,...
    'Position', figpos,...
    'NumberTitle', p.numbertitle,...
    'Menubar', p.menubar);

%toolbar items
handles.toolbar = uitoolbar('Parent', handles.figure);

handles.tool_stack = uitoggletool('Parent', handles.toolbar,...
    'Icon','stack_off.png',...
    'Tooltip','Stack the plot',...
    'Visible','on',...
    'Separator','off');

statedata(1).icon = 'stack_off.png';
statedata(1).tooltip = 'Plot channels on a single axis';
statedata(2).icon = 'stack_on.png';
statedata(2).tooltip = 'Plot each channel on its own axis';
handles.tool_stack.UserData = statedata;

handles.tool_negup = uitoggletool('Parent', handles.toolbar,...
    'Icon','posup_off.png',...
    'Tooltip','Plot with positive up',...
    'Visible','on',...
    'Separator','on');
statedata(1).icon = 'posup_off.png';
statedata(1).tooltip = 'Plot with positive up';
statedata(2).icon = 'posup_on.png';
statedata(2).tooltip = 'Plot with negative up';
handles.tool_negup.UserData = statedata;

handles.tool_ica = uitoggletool('Parent', handles.toolbar,...
    'Icon','ica_off.png',...
    'Tooltip','Plot ICA components',...
    'Visible','on',...
    'Separator','on');
statedata(1).icon = 'ica_off.png';
statedata(1).tooltip = 'Plot ICA components';
statedata(2).icon = 'ica_on.png';
statedata(2).tooltip = 'Plot EEG channels';
handles.tool_ica.UserData = statedata;

handles.tool_projica = uitoggletool('Parent', handles.toolbar,...
    'Icon','projica_on.png',...
    'Tooltip','Stop projecting selected ICA components',...
    'Visible','on',...
    'Separator','off');
statedata(1).icon = 'projica_off.png';
statedata(1).tooltip = 'Project selected ICA components';
statedata(2).icon = 'projica_on.png';
statedata(2).tooltip = 'Stop projected selected ICA components';
handles.tool_projica.UserData = statedata;

handles.tool_scale = uipushtool('Parent', handles.toolbar,...
    'Icon','scale.png',...
    'Tooltip','Auto scale the plot',...
    'Visible','on',...
    'Separator','on');

%create the grid layout
handles.gl = uigridlayout('Parent', handles.figure,...
    'ColumnWidth',{'1x','1x'},...
    'RowHeight',{35, '1.5x', '1x', 40}, ...
    'Padding', [0,0,0,0]);

%main plotting axis
%************************************************************
handles.axis_main = uiaxes(...
    'Parent', handles.gl,...
    'Units', 'Pixels',...
    'OuterPosition', [10,50,W/2,H-100],...
    'Interactions', []);
handles.axis_main.Layout.Column = 1;
handles.axis_main.Layout.Row = [2,3];


handles.panel_summaryimage = uipanel(...
    'Parent', handles.gl,...
    'Units', 'Pixels');
  %  'OuterPosition', [W/2+30, H/3, W/2-40, (H/3 * 2) - 50]);
handles.panel_summaryimage.Layout.Column = 2;
handles.panel_summaryimage.Layout.Row = [1,2];

handles.axis_quickaverage = uiaxes(...
    'Parent', handles.gl,...
    'Units', 'Pixels',...
    'Color', 'w',...
    'Interactions', []);
 handles.quick_average.Layout.Column = 2;
 handles.quick_average.Layout.Row = [3,4];
 
 % 'OuterPosition', [W/2+30, 30, W/2-40, H/3-50],...
  

handles.label_hoverChannel = uilabel(...,
    'Parent', handles.figure,...
    'Position', [50, H-65, 200, 25], ...
    'FontColor', 'k',...
    'HorizontalAlignment', 'left');

handles.axis_main.Toolbar.Visible = 'off';
temp = handles.axis_main.InnerPosition;

handles.slider_datascroll = uislider(...
    'Parent', handles.figure,...
    'Position', [temp(1),30,temp(3),3],...
    'Limits', [0,100],...
    'MajorTicks', [],...
    'MinorTicks', []);

 handles.image_trialstatus = uiaxes(...
     'Parent', handles.figure,...
     'InnerPosition', [temp(1),15,temp(3),15], ...
     'UserData', [temp(1),15,temp(3),15], ...
     'Units', 'pixels',...
     'XLimitMethod','tight',...
     'YLimitMethod','tight');
    % 'ScaleMethod', 'stretch');

handles.axis_trialstatus.Toolbar.Visible = 'off';

handles.panel_subjpanel = uipanel(...
    'Parent', handles.figure,...
    'Position', [1, H-35, 120, 35],...
    'Title', '');

handles.dropdown_subjselect = uidropdown(...
    'Parent', handles.panel_subjpanel,...
    'Position', [10, 5, 100, 25],...
    'BackgroundColor',p.goodsubjectcolor,...
    'FontColor','w');

% handles.label_subjectstatus = uilabel(...,
%     'Parent', handles.panel_subjpanel,...
%     'Position', [120, 5, 100, 25], ...
%     'FontColor', 'w',...
%     'HorizontalAlignment', 'center');

%*************************************************************************
%view controls panel
handles.panel_trialpanel = uipanel(...
    'Parent', handles.figure,...
    'Position', [handles.panel_subjpanel.Position(1) + handles.panel_subjpanel.Position(3)-1,...
    H-35, 345, 35],...
    'Title', '');

%*************************************************************************

handles.button_trialstatus = uibutton(...,
   'Parent', handles.panel_trialpanel,...
   'Position', [10,5,75,25], ...
   'Text', 'Good', ...
   'BackgroundColor', p.goodtrialcolor,...
   'FontColor', 'w');

handles.edit_badtrialcount = uilabel(...,
    'Parent', handles.panel_trialpanel,...
    'Position', [130,5,150,25], ...
    'Text', 'bad trial counter',...
    'BackgroundColor', p.backcolor,...
    'FontColor', p.textfieldfontcolor,...
    'HorizontalAlignment', 'center');
%**************************************************************************
handles.panel_scalepanel = uipanel(...
    'Parent', handles.figure,...
    'Position', [handles.panel_trialpanel.Position(1)+ handles.panel_trialpanel.Position(3)-1, ...
    H-35, 230, 35],...
    'Title', '');

% handles.button_autoscale = uibutton(...
%     'Parent', handles.panel_scalepanel,...
%     'Position', [10, 5, 100, 25],...
%     'Text', 'from data',...
%     'Backgroundcolor', p.buttoncolor, ...
%     'FontColor', p.buttonfontcolor);

handles.spinner_changescale = uispinner(...
    'Parent', handles.panel_scalepanel,...
    'Position', [120, 5, 100, 25],...
    'Limits', [1, inf],...
    'RoundFractionalvalues', 'on', ...
    'ValueDisplayFormat', '%i mV');

clear temp

%plot menu
handles.menu_plot = uimenu(handles.figure, 'Label', 'Plot Options');
handles.menu_icplot = uimenu(handles.menu_plot, 'Label', 'Show map for selected ICs', 'Checked', true);
handles.menu_quickave = uimenu(handles.menu_plot, 'Label', 'Show quick average', 'Checked', true);
handles.menu_overlay = uimenu(handles.menu_plot, 'Label', 'Overlay original and projected data', 'Checked', true);


%ica menu
handles.menu_ICA = uimenu(handles.figure, 'Label', 'ICA Options');
handles.menu_selectIC = uimenu(handles.menu_ICA, 'Label', 'Select ICs');
handles.menu_brain = uimenu(handles.menu_selectIC, 'Label', 'Brain', 'UserData', 1);
handles.menu_noise = uimenu(handles.menu_selectIC, 'Label', 'Noise', 'UserData', 2:6);
handles.menu_other = uimenu(handles.menu_selectIC, 'Label', 'Other', 'UserData', 7);
handles.menu_project = uimenu(handles.menu_ICA, 'Label', 'Project');
handles.menu_withsel = uimenu(handles.menu_project, 'Label', 'keep selected', 'UserData', 0, 'Checked', true, 'Separator', 'on');
handles.menu_withoutsel = uimenu(handles.menu_project, 'Label', 'exclude selected', 'UserData', 1);
handles.menu_icatobad = uimenu(handles.menu_ICA, 'Label', 'Mark components as bad');
handles.menu_icaselbad = uimenu(handles.menu_icatobad,'Label', 'all selected', 'Separator', 'on', 'Tag', 'selected');
handles.menu_icaunselbad = uimenu(handles.menu_icatobad,'Label', 'all unselected', 'Tag', 'unselected');
handles.menu_icaclear = uimenu(handles.menu_icatobad,'Label', 'remove marks', 'Tag', 'remove');

%Reject options
handles.menu_clean = uimenu(handles.figure, 'Label', 'Trial Markers');
handles.menu_clearchans = uimenu(handles.menu_clean, 'Label', 'Unselect channels');
handles.menu_clearcomps = uimenu(handles.menu_clean, 'Label', 'Unselect components');
handles.menu_remove = uimenu(handles.menu_clean, 'Label','Remove bad trial markers', 'Separator', 'on');

handles.menu_rman = uimenu(handles.menu_remove, 'Label', 'manual marks', 'Tag', 'rejmanual');
handles.menu_rthresh = uimenu(handles.menu_remove, 'Label', 'threshold marks', 'Tag', 'rejthresh');
handles.menu_rkurt = uimenu(handles.menu_remove, 'Label', 'kurtosis marks', 'Tag', 'rejkurt');
handles.menu_rconst = uimenu(handles.menu_remove, 'Label', 'trend marks', 'Tag', 'rejconst');
handles.menu_rjp = uimenu(handles.menu_remove, 'Label', 'joint prob. marks', 'Tag', 'rejjp');
handles.menu_rall = uimenu(handles.menu_remove, 'Label', 'all marks', 'Tag', 'rejmanual rejthresh rejkurt rejconst rejjp');

handles.menu_icplot.Callback = {@callback_togglecheck, handles};
handles.menu_quickave.Callback = {@callback_togglecheck, handles};
handles.menu_overlay.Callback = {@callback_togglecheck, handles};
handles.menu_clearchans.Callback = {@callback_deselectchans, handles, 0};
handles.menu_clearcomps.Callback = {@callback_deselectchans, handles, 1};

handles.menu_brain.Callback = {@callback_selectICs, handles};
handles.menu_noise.Callback = {@callback_selectICs, handles};
handles.menu_other.Callback = {@callback_selectICs, handles};
handles.menu_icaselbad.Callback = {@callback_setcompbadstatus, handles};
handles.menu_icaunselbad.Callback = {@callback_setcompbadstatus, handles};
handles.menu_icaclear.Callback = {@callback_setcompbadstatus, handles};

handles.menu_withsel.Callback = {@callback_toggleprojopt, handles};
handles.menu_withoutsel.Callback = {@callback_toggleprojopt, handles};

handles.menu_rman.Callback = {@callback_removetrialmarkers, handles};
handles.menu_rthresh.Callback = {@callback_removetrialmarkers, handles};
handles.menu_rkurt.Callback = {@callback_removetrialmarkers, handles};
handles.menu_rconst.Callback = {@callback_removetrialmarkers, handles};
handles.menu_rjp.Callback = {@callback_removetrialmarkers, handles};
handles.menu_rall.Callback = {@callback_removetrialmarkers, handles};

handles.figure.CloseRequestFcn = {@closeplot, handles};
handles.slider_datascroll.ValueChangingFcn = {@callback_drawdata, handles};
handles.spinner_changescale.ValueChangedFcn = {@callback_drawdata, handles};
handles.dropdown_subjselect.ValueChangedFcn = {@callback_loadnewfile, study, handles};
handles.tool_stack.ClickedCallback = {@callback_toggletool, handles};
handles.tool_negup.ClickedCallback = {@callback_toggletool, handles};
handles.tool_projica.ClickedCallback = {@callback_toggletool, handles};
handles.tool_ica.ClickedCallback = {@callback_toggletool, handles};
handles.button_trialstatus.ButtonPushedFcn = {@callback_toggletrialstatus, handles};
handles.tool_scale.ClickedCallback = {@callback_setscale, handles, 1};
handles.figure.WindowKeyPressFcn = {@callback_handlekeyevents, handles};
handles.figure.WindowScrollWheelFcn = {@callback_handlemouseevents, handles};
handles.figure.WindowButtonMotionFcn = {@callback_mouseoverplot, handles};
handles.button_clearstatus.ButtonPushedFcn = {@callback_cleartrialstatus, handles};


%do a more sophisticated check later to make sure this information matches
handles.dropdown_subjselect.Items   = {study.subject.ID};
handles.dropdown_subjselect.ItemsData = 1:length(study.subject);
handles.dropdown_subjselect.UserData = filenames;

plot.scrollevent = 'scale';
plot.projectopt = 0; %this is the "include" state
plot.params = p;
handles.figure.UserData = plot;
callback_loadnewfile([], [], study, handles);

%*************************************************************************
function initialize_icmenus(h)
    
    p = h.figure.UserData;
    
    %if there is no ica information
    if isempty(p.EEG.icasphere)
        checked_state = false;
        enabled_state = 'off';
    else
        checked_state = true;
        enabled_state = 'on';
        p.EEG.icaact = [];
        if isempty(p.EEG.icaact)
            p.EEG.icaact = (p.EEG.icaweights*p.EEG.icasphere)*p.EEG.data(p.EEG.icachansind,:); % automatically does single or double
            p.EEG.icaact    = reshape( p.EEG.icaact, size(p.EEG.icaact,1), p.EEG.pnts, p.EEG.trials);
        end
    end
    
    h.menu_icplot.Checked = checked_state;
    h.menu_icplot.Enable = enabled_state;
    h.menu_overlay.Checked = checked_state;
    h.menu_overlay.Enable = enabled_state;
    h.menu_ICA.Enable = enabled_state;
    h.menu_clearcomps.Enable = enabled_state;
    h.tool_projica.State = checked_state;
    h.tool_projica.Enable = enabled_state;
    h.tool_ica.Enable = enabled_state;
    h.menu_selectIC.Enable = isfield(p.EEG.etc, 'ic_classification');
%*************************************************************************
function callback_toggletool(hObject,event,h)
    
    %figure out what state the toggle is in
    indx = hObject.State + 1;
    sd = hObject.UserData;
    hObject.Icon = sd(indx).icon;
    hObject.Tooltip = sd(indx).tooltip;
  
    callback_drawdata(hObject,event, h);
%************************************************************************
function callback_handlekeyevents(hObject, event, h)

%disp(event.Key)
key_event = event.Key;

switch key_event
    case 'leftarrow'
        v = h.slider_datascroll.Value;
        if v>1; h.slider_datascroll.Value = v - 1; end
        callback_drawdata([],[],h);
        
    case 'rightarrow'
        v = h.slider_datascroll.Value;
        if v<h.slider_datascroll.Limits(2); h.slider_datascroll.Value = v + 1; end
        callback_drawdata([],[],h);
        
    case 'uparrow'
        scale = h.spinner_changescale.Value;
        scale = scale * 1.25;
        h.spinner_changescale.Value = scale;
        callback_drawdata([],[],h);
        
    case 'downarrow'
        scale = h.spinner_changescale.Value;
        scale = scale * .75;
        h.figure.UserData = p;
        h.spinner_changescale.Value = scale;
        callback_drawdata([],[],h);
        
    case 'b'
        callback_toggletrialstatus([],[],h)
end
%**************************************************************************
function callback_mouseoverplot(hObject, event, h)

obj = hittest(h.figure);
otype = class(obj);

if strcmp(otype, 'matlab.graphics.chart.primitive.Line') 
     if ~isempty(obj.UserData)
         t = h.axis_main.CurrentPoint;
         t = t(2,1);
         h.label_hoverChannel.Text = sprintf('%s : %3.2f ms.\n', obj.UserData,t);
     end
else
    h.label_hoverChannel.Text = '';
 end

%***************************************************************************
function callback_handlemouseevents(hObject, event, h)

scroll_dir = event.VerticalScrollCount;

p = h.figure.UserData;

switch p.scrollevent
    case 'scale'
        cscale = h.spinner_changescale.Value;
        ch_amnt = cscale * .25 * scroll_dir;
        cscale = cscale + ch_amnt;
        h.spinner_changescale.Value = cscale;
        callback_drawdata([],[],h);
        
    case 'trial'       
        ctrial = h.slider_datascroll.Value;
        ctrial = ctrial + scroll_dir;
        if ctrial < 1; ctrial=1; end
        if ctrial > p.EEG.trials; ctrial = p.EEG.trials;  end
        h.slider_datascroll.Value = ctrial;
        callback_drawdata([],[],h);
end

%**************************************************************************
function callback_deselectchans(hObject, eventdata, h, clear_comps)


    p = h.figure.UserData;

if clear_comps
    p.selcomps = zeros(1, size(p.EEG.icaweights, 1));
else
    p.selchans = zeros(1, p.EEG.nbchan);
end
h.figure.UserData = p;

callback_drawdata([],[],h);

%**************************************************************************
function callback_selectchannel(hobject, eventdata,h, ch_num)

    plot_ica = h.tool_ica.State;
    p = h.figure.UserData;
    if plot_ica
        p.selcomps(ch_num) = ~p.selcomps(ch_num);
    else
        p.selchans(ch_num) = ~p.selchans(ch_num);
    end
    h.figure.UserData = p;
    
    callback_drawdata([],[],h);
%************************************************************************
function callback_setcompbadstatus(hObject, eventdata, h)
    
    p = h.figure.UserData;
    
    comps = p.selcomps;
    
    switch hObject.Tag
            
        case 'unselected'
            comps = ~comps;
        case 'remove'
            comps(1:end) = 0;
    end
    
    p.EEG.reject.gcompreject = comps;
    p.EEG.saved = 'no';
    h.figure.UserData = p;
    callback_drawdata([],[],h);
    
    
%*************************************************************************    
function callback_setscale(hObject, eventdata, h, redraw)
    
stacked = h.tool_stack.State;
plotica = h.tool_ica.State;

plot = h.figure.UserData;
if plotica
    if stacked
        scale = round(max(range(plot.EEG.icaact(:,:,1)')) * 1.5);
    else
        scale = round(max(range(plot.EEG.icaact(:,:,1)')) /4);
    end
else
    if stacked
        scale = round(max(range(plot.EEG.data(:,:,1)')) * 1.5);
    else
        scale = round(max(range(plot.EEG.data(:,:,1)')) /4);
    end
end

h.spinner_changescale.Value = double(scale);
if redraw; callback_drawdata([],[],h); end


%***************************************************************************
function callback_loadnewfile(hObject, eventdata, study, h)

%load the general data    
plot = h.figure.UserData;

%get the current participant number and filename
snum = h.dropdown_subjselect.Value;
fnames = h.dropdown_subjselect.UserData;
filename = fnames{snum};

%make sure something was passed
if isempty(filename)
    uialert(h.figure, 'No data to load and plot!');
    return
end

%make sure it is a file that exists
if exist(filename, 'file') ~= 2
    uialert(h.figure, 'The selected file does not seem to exist.  Please double check the file location.');
    return
end

pb = uiprogressdlg(h.figure, "Indeterminate",'on');

%check to see if the currently displayed file needs saving
saveflag = false;
if isfield(plot, 'EEG')
    %this also means that no initial scale has been established , so we can
    %do that here
    fprintf('checking old eeg file for changes...')
    if contains(plot.EEG.saved, 'no')
        fprintf('changes detected, saving current file\n');
        if ~isempty(eventdata)   
            old_snum = eventdata.PreviousValue;
            saveflag = true;
        else
            fprintf('whoops - cannot determine which file to save')
        end
    end
end


%save the current file if needed and load the new one too.
%pb = uiprogressdlg(h.figure, 'Message', '', 'Title', 'Switching participants', 'Indeterminate', 'on');
if saveflag
    pb.Message = 'Saving current subject file.';
    oldfilename = fnames{old_snum};
    EEG = plot.EEG;
    
    wwu_SaveEEGFile(EEG, oldfilename);
  %  save(oldfilename, '-v6', '-mat', 'EEG');
end
pb.Message = 'Loading new subject file';

%load the data
EEG = wwu_LoadEEGFile(filename);

%close(pb);
if isempty(EEG.reject.rejmanual)
    EEG.reject.rejmanual = zeros(1, EEG.trials);
    EEG.saved = 'no';
end

%make sure it is the correct data type
if EEG.trials == 1
    uialert(h.figure, 'The file may contain continuous data. Please use the continuous file viewer instead.');
    return
end

%show the user the status of this participant
if contains(study.subject(snum).status, 'good')
    h.dropdown_subjselect.BackgroundColor = plot.params.goodsubjectcolor;
else    
    h.dropdown_subjselect.BackgroundColor = plot.params.badsubjectcolor;
end

btrials = study_GetBadTrials(EEG);
h.edit_badtrialcount.Text = sprintf('%i (%i%%) bad trials', sum(btrials), round((sum(btrials)/EEG.trials)*100));

%initialize the selected channels
%if ~isfield(plot, 'selchans') || isempty(plot.selchans)
    plot.selchans = zeros(1, EEG.nbchan);
    plot.selcomps = zeros(1, size(EEG.icaweights,1));
%end

plot.EEG = EEG;
h.figure.UserData = plot;
callback_setscale([],[],h,0)
%initialize_icmenus(h)

%reset the slider
h.slider_datascroll.Limits = [1, EEG.trials];
h.slider_datascroll.Value = 1;
if EEG.trials < 200
    step = round(EEG.trials/20, 0);
else
    step = round(EEG.trials/20, -1);
end
h.slider_datascroll.MajorTicks = [step:step:EEG.trials];
pb.Message = 'Drawing the data';
callback_drawdata([],[],h);
close(pb);

%*************************************************************************
%callback function for drawing the main data scroll plot
function callback_drawdata(hObject, eventdata, h)

%get some plotting information
p = h.figure.UserData;

stacked = h.tool_stack.State;
invert = ~h.tool_negup.State;
projica = h.tool_projica.State;
plotica = h.tool_ica.State;
overlay = h.menu_overlay.Checked;

scale = h.spinner_changescale.Value;


%resize the plotting window here just to see if it will work


%get the plotting position from the slider
if ~isempty(eventdata)
   if contains(eventdata.EventName, 'ValueChanging')
        trialnum = round(eventdata.Value);
   else
    trialnum = round(h.slider_datascroll.Value);
    h.slider_datascroll.Value = trialnum;
   end   
else
    trialnum = round(h.slider_datascroll.Value);
    h.slider_datascroll.Value = trialnum;
end


if trialnum < 1; trialnum = 1; end
if trialnum > p.EEG.trials; trialnum = p.EEG.trials; end

h.axis_main.Title.String = sprintf('trial %i of %i', trialnum, p.EEG.trials);
msg = getbadtrialstring(p.EEG, trialnum);
if ~isempty(msg)
    h.button_trialstatus.BackgroundColor = p.params.badtrialcolor;
    h.button_trialstatus.Text = 'Bad';
    h.axis_main.Color = [1,1,.8];
else
    h.button_trialstatus.BackgroundColor = p.params.goodtrialcolor;
    h.button_trialstatus.Text = 'Good';
    h.axis_main.Color = 'w';
end    

%grab the data to plot
%the user can decide between plotting the ICA activations of the normal
%data
if plotica
    d = squeeze(p.EEG.icaact(:,:,trialnum));
    selected = p.selcomps;
    overlay = false;
else
    d = squeeze(p.EEG.data(:,:,trialnum));
    selected = p.selchans;
    if projica && (sum(p.selcomps) > 0)
        if p.projectopt
            comps = find(~p.selcomps);
        else
            comps = find(p.selcomps);
        end
        d2 = icaproj(d, p.EEG.icaweights * p.EEG.icasphere, comps);
        if ~overlay
            d = d2;
            clear d2
        end
    else
        overlay = false;
    end    

end
    
t = p.EEG.times;

%scale it so that that channels are distributed vertically rather than
%stacked in a butterfly plot
if ~stacked
    scalefac = (0:1:size(d,1)-1) * scale;
    scalefacarray = repmat(scalefac', 1, p.EEG.pnts);
    d = d + scalefacarray;
    if overlay 
        d2 = d2 + scalefacarray;
    end
end

%plot the data
if overlay
    plot(h.axis_main, t, d2, 'Color', 'b');
    hold(h.axis_main, 'on');
    ph = plot(h.axis_main, t,d, 'Color', 'r');
    hold(h.axis_main, 'off');
else
   
    ph = plot(h.axis_main, t,d);
end
%assign a callback to each line object so it is easy to allow users to
%select a specific channel.  Also determine if the channel is selected and
%increase its line thickness
for ii = 1:length(ph)
    ph(ii).ButtonDownFcn = {@callback_selectchannel, h, ii};
    ph(ii).LineWidth = (selected(ii) * 2.5) + .5;
    if plotica 
        ph(ii).UserData = sprintf('comp %i', ii);
    else
        ph(ii).UserData = p.EEG.chanlocs(ii).labels;
    end
    if plotica
        if p.EEG.reject.gcompreject(ii)
            ph(ii).Color = p.params.badicactcolor;
        else
            ph(ii).Color = p.params.goodicactcolor;

        end
    end
end


if ~stacked
    h.axis_main.YTick = scalefac;
    if plotica
        h.axis_main.YTickLabel = 1:length(p.EEG.chanlocs);
    else
        h.axis_main.YTickLabel = {p.EEG.chanlocs.labels};
    end
    ylims = [scalefac(1) - scale, scalefac(end) + scale];
    h.axis_main.YLim = ylims;
else
    ylims = [-scale/2, scale/2];
    h.axis_main.YLim = ylims;
    h.axis_main.YTickMode = 'auto';
    h.axis_main.YTickLabelMode = 'auto';
end

xlims = [t(1), t(end)]; 
h.axis_main.XLim = xlims;

text_yloc = ylims(1);
if stacked && ~invert
    h.axis_main.YDir = 'normal';
    text_yloc = ylims(2);
else
    h.axis_main.YDir = 'reverse';
end    

h.axis_main.XGrid = 'on';
h.axis_main.YGrid = 'on';


%get event markers that lie within the plotting range

 if ~isempty(p.EEG.epoch(trialnum).eventlatency)
     n_events = length(p.EEG.epoch(trialnum).eventlatency);
     indx = [p.EEG.epoch(trialnum).eventlatency{:}]==0;
     if sum(indx) > 1 % we have two timelocking events - one is probably a bin marker
         n_events = n_events - 1;  %the bin is the last event so this is  a simple way to ignore it
     end
     for ii =1:n_events
         evt_time = p.EEG.epoch(trialnum).eventlatency{ii};
         evt_label = p.EEG.epoch(trialnum).eventtype{ii};
         if isnumeric(evt_label)
             evt_label = num2str(evt_label);
         end
         line(h.axis_main, [evt_time, evt_time], ylims, 'Color','k', 'linewidth', 2);
         text(h.axis_main, evt_time+10, text_yloc, evt_label, 'VerticalAlignment', 'Top');
     end
 end
 

%plot the ica components maps for each activation when in ica mode
if plotica
    plot_icacomps(h,p);
else
    plot_erpimage(h, p)
end
plot_quickave(h,p);
    
if ~isempty(msg); text(h.axis_main, p.EEG.times(1), text_yloc, msg,'FontSize', 20, 'Color', [1,0,0],'VerticalAlignment', 'Top'); end

%draw an image of where the bad trials are located
status_image = create_badtrialimage(p);
ps = h.image_trialstatus.InnerPosition;
im = imshow(status_image, 'Parent', h.image_trialstatus, 'XData', [1,ps(3)], 'YData',[1, ps(4)]);
h.image_trialstatus.XLim = [1, im.XData(2)];
h.image_trialstatus.YLim = [1, im.YData(2)];

%**************************************************************************
function callback_toggletrialstatus(hObject, eventdata, h)


p = h.figure.UserData;

trialnum = round(h.slider_datascroll.Value);
if isempty(p.EEG.reject.rejmanual)
    p.EEG.reject.rejmanual(trialnum) = 1;
    
else
    p.EEG.reject.rejmanual(trialnum) = ~p.EEG.reject.rejmanual(trialnum);

end
if p.EEG.reject.rejmanual(trialnum) == 0
    h.button_trialstatus.Text = 'Good';
    h.button_trialstatus.BackgroundColor = p.params.goodtrialcolor;
else
    h.button_trialstatus.Text = 'Bad';
    h.button_trialstatus.BackgroundColor = p.params.badtrialcolor;
end 

p.EEG.saved = 'no';
h.figure.UserData = p;
callback_drawdata([],[],h);
%**************************************************************************
function callback_cleartrialstatus(hObject, eventdata, h)
    
    p = h.figure.UserData;
    
    p.EEG.saved = 'no';
    p.EEG.reject.rejmanual = zeros(1,p.EEG.trials);
    h.figure.UserData = p;
    
    callback_drawdata([],[],h);
%*************************************************************************    
function status_image = create_badtrialimage(p)
    
%initialize the image
status_image = double(zeros(1,p.EEG.trials,3));

%initialize the background to the plot color
 for ii = 1:3
     status_image(1,1:p.EEG.trials,ii) = p.params.backcolor(ii);
 end
 
 btrials = study_GetBadTrials(p.EEG);
 
  status_image(1,btrials,:) = repmat([1,0,0], sum(btrials),1);
  status_image = repmat(status_image, [10,1,1]);
%********************************************************************     
function mystr = getbadtrialstring(EEG, trialnum)
    
    
    mystr = [];
    
    if ~isempty(EEG.reject.rejmanual)
        if EEG.reject.rejmanual(trialnum)==1; mystr = "Manual: "; end
    end
    
    if ~isempty(EEG.reject.rejthresh)
        if EEG.reject.rejthresh(trialnum)==1; mystr = [mystr, "Threshold: "]; end
    end
    
    if ~isempty(EEG.reject.rejkurt)
        if EEG.reject.rejkurt(trialnum)==1; mystr = [mystr, "Kurtosis: "];end
    end
    
    if ~isempty(EEG.reject.rejconst)
        if EEG.reject.rejconst(trialnum)==1; mystr = [mystr, "Trend: "];end
    end
    
    if ~isempty(EEG.reject.rejjp)
        if EEG.reject.rejjp(trialnum)==1; mystr = [mystr, "Joint Prob: "];end
    end
%**************************************************************************    
%plots ica components associated with selected channels when the plot is in
%ICA plotting mode
function plot_icacomps(h,p)
    
plotcomp = h.menu_icplot.Checked;
projica = h.tool_projica.State;
       
ax = h.panel_summaryimage;
lastplot = ax.UserData;
if ~isfield(lastplot, 'mapind')
    lastplot.mapind = [];
end
mapind = find(p.selcomps);
if isempty(mapind); 
    delete(ax.Children)
    ax.Title = 'No selected components to display';
    return; 
end
if isequal(mapind, lastplot.mapind) && lastplot.plotica; return; end

ax.Title = 'Selected ICA components';
wratio = ax.InnerPosition(3)/ax.InnerPosition(4);
cols = floor(sqrt(length(mapind)) * wratio); if cols<1; cols=1;end
rows = ceil(length(mapind)/cols); if rows < 1; rows=1;end

if isfield(p.EEG.etc, 'ic_classification')
    class_label = true;
    [v, i] = max(p.EEG.etc.ic_classification.ICLabel.classifications, [],2);
else
    class_label = false;
end

t = tiledlayout(ax, rows, cols);
for ii = 1:length(mapind)
    ah = nexttile(t);
    wwu_topoplot(p.EEG.icawinv(:, mapind(ii)), p.EEG.chanlocs, 'axishandle', ah);
    mylabel = sprintf('IC %i', mapind(ii));
    if class_label
        mylabel = sprintf('%s: %s (%2.1f%%)', mylabel, p.EEG.etc.ic_classification.ICLabel.classes{i(mapind(ii))}, v(mapind(ii)) * 100);
    end
    ah.Title.String =mylabel;
end
t.TileSpacing = 'compact';
t.Padding = 'compact';
lastplot.mapind = mapind;
lastplot.plotcomp = plotcomp;
lastplot.plotica = true;

ax.UserData = lastplot;

%***********************************************************************
function plot_erpimage(h, p, d)

projica = h.tool_projica.State;
plotcomp = h.menu_icplot.Checked;

ax = h.panel_summaryimage;
lastplot = ax.UserData;
if ~isstruct(lastplot)
    lastplot = struct();
end

if ~isfield(lastplot, 'erpind')
    lastplot.erpind = [];
end
if ~isfield(lastplot, 'projica')
    lastplot.projica = [];
end

erpind = find(p.selchans);
if isempty(erpind); 
    delete(ax.Children);
    ax.Title = 'No selected channels to display';
    return; 
end
if isequal(erpind, lastplot.erpind) && isequal(projica, lastplot.projica) && ~lastplot.plotica; return; end

ax.Title = 'Selected EEG Channels';
wratio = ax.InnerPosition(3)/ax.InnerPosition(4);
cols = floor(sqrt(length(erpind)) * wratio);
rows = ceil(length(erpind)/cols);

pdata = p.EEG.data;
if projica && (sum(p.selcomps) > 0)
    if p.projectopt
        comps = find(~p.selcomps);
    else
        comps = find(p.selcomps);
    end
    pdata = reshape(pdata, [p.EEG.nbchan, p.EEG.trials * p.EEG.pnts]);
    pdata = icaproj(pdata, p.EEG.icaweights * p.EEG.icasphere, comps);
    pdata = reshape(pdata, [p.EEG.nbchan, p.EEG.pnts, p.EEG.trials]);
end
t = tiledlayout(ax, rows, cols);
for ii = 1:length(erpind)
    ah = nexttile(t);
    d = squeeze(pdata(erpind(ii),:,:));
    d = imgaussfilt(d,2);
    imagesc(ah,p.EEG.times, 1:p.EEG.trials, d');
    line(ah,[0,0], [1, p.EEG.trials], 'Color', 'k', 'LineWidth', 3);
    mylabel = sprintf('%i:%s', erpind(ii), p.EEG.chanlocs(erpind(ii)).labels);
    ah.Title.String =mylabel;
    ah.XLabel.String = 'Time (ms)';
    ah.YLabel.String = 'Trials';
end
t.TileSpacing = 'compact';
t.Padding = 'compact';
lastplot.erpind = erpind;
lastplot.projica = projica;
lastplot.plotica = false;

ax.UserData = lastplot;
%***********************************************************************
function plot_quickave(h, p)
    
 %
 %plotica = h.check_icaact.Value;
new.plotave = h.menu_quickave.Checked;
new.projica = h.tool_projica.State;
new.invert = ~h.tool_negup.State;




%now exit if  the option to plot the average is not selected
if ~new.plotave 
    return
end

%get the bad trials so that they can be exlcuded from the average
new.btrials = ~study_GetBadTrials(p.EEG);

if p.projectopt 
    new.comps = find(~p.selcomps);
else
    new.comps = find(p.selcomps);
end

if new.projica  && sum(p.selcomps) > 0
   
    d = icaproj(p.EEG.data(:,:), p.EEG.icaweights * p.EEG.icasphere, new.comps);
    d = reshape(d, size(p.EEG.data));
    ave = mean(d(:,:,new.btrials),3);
else
    ave = mean(p.EEG.data(:,:,new.btrials), 3);
end

%remove the offset from the data.
if p.EEG.times(1) >= 0
    bline = mean(ave, 2);
else     
    bline = mean(ave(:, p.EEG.times < 0), 2);
end

bline = repmat(bline, [1,p.EEG.pnts]);
ave = ave - bline;

% clf(fh);
% fh.Color = p.params.textfieldbackcolor;

%ax = axes(fh, 'Position', [.05,.1,.9,.95]);
plot(h.axis_quickaverage, p.EEG.times, ave');
if new.invert 
    h.axis_quickaverage.YDir = 'reverse'; 
else
    h.axis_quickaverage.YDir = 'normal'; 
end
h.axis_quickaverage.XGrid = 'on'; h.axis_quickaverage.YGrid = 'on';
line(h.axis_quickaverage, [0,0], h.axis_quickaverage.YLim, 'Color', 'k', 'LineWidth', 2);
%fh.UserData = new;

%**************************************************************************    
 function callback_selectICs(hObject, event, h)
     
     p = h.figure.UserData;
     
     classes = hObject.UserData;
     prob_vec = sum(p.EEG.etc.ic_classification.ICLabel.classifications(:,classes),2);
     p.selcomps(find(prob_vec>.5)) = 1;
     
     h.figure.UserData = p;
     callback_drawdata([],[],h);
 %*************************************************************************    
function callback_toggleprojopt(hObject, event, h)
    
    p = h.figure.UserData;
    p.projectopt = hObject.UserData;
    
    if p.projectopt
        h.menu_withsel.Checked = false;
        h.menu_withoutsel.Checked = true;
    else
        h.menu_withsel.Checked = true;
        h.menu_withoutsel.Checked = false;
    end
    
    h.figure.UserData = p;
    
    callback_drawdata([],[],h);
    
function callback_togglecheck(hObject, event,h)
    
    hObject.Checked = ~hObject.Checked;
    callback_drawdata([],[],h);
%**************************************************************************
function callback_removetrialmarkers(hObject, event, h)   
    
    p = h.figure.UserData;
    
    p.EEG = study_removerejectmarkers(p.EEG, hObject.Tag);
    p.EEG.saved = 'no';
    
    h.figure.UserData = p;
    callback_drawdata([],[],h);
    
%**************************************************************************
        
function closeplot(hObject, event, h)
        
fh = findobj('Tag', 'icamap');
if ~isempty(fh)
    close(fh)
end
fh = findobj('Tag', 'quickave');
if ~isempty(fh)
    close(fh)
end

delete(h.figure);




 