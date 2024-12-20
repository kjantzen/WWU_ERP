%study_Averager_GUI() - GUI for collecting information and computing the 
%                       average within and across participants.
%Usage:
%>> study_Averager_GUI(study, filenames, bingroup);
%
%Required Inputs:
%   study       -   an hcnd STUDY structure passed from the hcnd eeg management
%                   software or from the command line. 
%
%   filenames   -   a cell array of filenames to average.  The resulting
%                   output file will containt the average of the trials 
%                   within each input file and the grand average across files.
%                   Conditions are defined by bin labels in each file
% Update 5/13/20 KJ Jantzen
%
function fh = study_Averager_GUI(study, filenames)

scheme = eeg_LoadScheme;
W = 400; H = 300;
FIGPOS = [(scheme.ScreenWidth-W)/2,(scheme.ScreenHeight-H)/2, W, H];

handles.figure = uifigure;
set(handles.figure, ...
    'Color', scheme.Window.BackgroundColor.Value,...
    'name', 'Create Average ERPs',...
    'NumberTitle', 'off', ...
    'menubar', 'none', ...
    'position', FIGPOS, ...
    'resize', 'off',...
    'units', 'pixels',...
    'WindowStyle', 'modal');
fh = handles.figure;

handles.panel1 = uipanel(...
    'Parent', handles.figure,...
    'Title','Averaging Options',...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'Position',[10, 40, W-20, H-50]);

Parent = handles.panel1;

handles.check_excludebadtrials = uicheckbox('parent', Parent,...
    'Text', 'Exclude bad trials before averaging',...
    'Value', 1, ...
    'Position', [20, 180, 300, 20],...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);

handles.check_excludebadcomps = uicheckbox('parent', Parent,...
    'Text', 'Project without bad components before averaging',...
    'Value', 1, ...
    'Position', [20, 140, 300, 20],...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);

handles.check_interpolate = uicheckbox('parent', Parent,...
    'Text', 'Interpolate deleted or missing channels before averaging',...
    'Value', 1, ...
    'Position', [20, 100, 300, 20],...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);

handles.check_excludebadsubjs = uicheckbox('parent', Parent,...
    'Text', 'Exclude bad participatns',...
    'Value', 1, ...
    'Position', [20, 60, 300, 20],...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);

uilabel('Parent', Parent,...
    'Text', 'Name for the average', ...
    'Position', [20, 20, 150, 20],...
    'FontName', scheme.Label.Font.Value,...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value);

handles.edit_outfilename = uieditfield(...
    'Parent', Parent,...
    'Position', [170, 20, 200, 20],...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontSize', scheme.Edit.FontSize.Value);


handles.button_average = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Average',...
    'Position', [W-90, 5, 80, 25],...
   'BackgroundColor',scheme.Button.BackgroundColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontSize', scheme.Button.FontSize.Value);

handles.button_cancel = uibutton(...
'Parent', handles.figure,...
    'Text', 'Cancel',...
    'Position', [W-180, 5, 80, 25],...
   'BackgroundColor',scheme.Button.BackgroundColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontSize', scheme.Button.FontSize.Value);

handles.button_average.ButtonPushedFcn = {@callback_DoAverage, handles};
handles.button_cancel.ButtonPushedFcn = {@callback_exit, handles};

if size(filenames,1) > 1
    handles.check_combine.Enable = 'on';
    handles.label_file.Enable = 'on';
    handles.edit_newfilename.Enable = 'on';
end

p.study = study;
p.filenames = filenames;

handles.figure.UserData  = p;

%**************************************************************************
%start of functions
%**************************************************************************
function callback_exit(hObject, eventdata, h)
    close(h.figure)
    
%**************************************************************************
function callback_DoAverage(hObject, eventdata, h)
p = h.figure.UserData;
study = p.study;

tic

%for now I think I will just do the average here rather than farm it out to the non-gui routine.
%This may change as things get more complex.

exclude_badtrials = h.check_excludebadtrials.Value;
exclude_badcomps = h.check_excludebadcomps.Value;
exclude_badsubjs = h.check_excludebadsubjs.Value;
interpolate_channels = h.check_interpolate.Value;
outfilename = h.edit_outfilename.Value;

parameters.operation = {'Operation', 'Time Average'};
parameters.date = {'Date and time', datetime("now")};
parameters.exclude_trial = {'Exclude Bad Trials', exclude_badtrials};
parameters.exclude_comps = {'Exclude Bad Components', exclude_badcomps};
parameters.exclude_subjs = {'Exclude Bad Subjects', exclude_badsubjs};
parameters.interp = {'Interpolate Missing Channels', interpolate_channels};

%set and create (if necessary) the output directory;
study_path = study_GetEEGPath;
outdir = eeg_BuildPath(study_path, study.path, 'across subject');

%check for an output filename
if isempty(outfilename)
    uialert(h.figure, 'Please enter a valid output filename.', 'Averaging Error');
    return
end

%create the output directory
if ~exist(outdir, 'Dir')
    mkdir(outdir)
end

%make sure there is something to process
if isempty(p.filenames)
    uialert(h.figure, 'Somehow you made it this far without selecting files', 'Averaging Error');
    delete(h.figure);
    return
end

pb = uiprogressdlg(h.figure);

%create a temporary version of each file in the across subject directory so
%that I can remove trials and or components in necessary

%if more than one set of files is selected, the outfile name will be incremented
reportColumnNames = {'Included in average', 'Trials Removed', 'Components Removed','Number of channels', 'Average File'};
reportRows = cell(length(p.filenames),1);
reportData = cell(length(p.filenames), 5);
loopCount = 0;
for ii = 1:size(p.filenames,1)
    
    %if the file exists already append a number to the end
    if exist(fullfile(outdir, [outfilename, '.GND']),'file')
        parselocal = max(strfind(outfilename, '_'));
        if isempty(parselocal)
            outfilename = [outfilename, '_2'];
        else
            fnum = str2num(outfilename(parselocal+1:end));
            if isempty(fnum)
               outfilename = [outfilename, '_2']; 
            else
                fnum = fnum + 1;
                outfilename = sprintf('%s_%i', outfilename(1:parselocal), fnum);
            end
        end
    end
    
    fcount = 0;
    flist = [];
    conditions = {};
    for jj = 1:size(p.filenames,2)
        loopCount = loopCount + 1;
        
        pb.Value = jj/size(p.filenames,2);
        pb.Message = 'Loading EEG Data';
        
        [fpath, fname, ~] = fileparts(eeg_BuildPath(p.filenames{ii,jj}));
        
        %figure out what subject this is and check to see if this subject
        %is a bad subject
  
        SDir = fpath(max(strfind(fpath, filesep))+1:end);
        sr = endsWith({study.subject.path}, SDir);
        snum = find(sr);
        if isempty(snum) || length(snum) > 1
            fprintf('Could not determine subject number.  All subjects will be included!\n');
            exclude_badsubjs = false;
        else
            if strcmp(study.subject(snum).status, 'bad') && exclude_badsubjs
                reportRows(loopCount) = p.filenames(ii,jj);
                reportData{jj, 1} = 'No';
                continue
            end
            %get any between subject condition information 
            conditions{end+1} = study.subject(snum).conditions;
        end
        
        %load the data
        EEG = wwu_LoadEEGFile(p.filenames{ii,jj});
        EEG.subject = study.subject(snum).ID;
        
        %initialize cell data for reporting averaging results to the process
        %log
        reportRows(loopCount) = p.filenames(ii,jj);
        reportData{loopCount,1} = 'Yes';
        reportData{loopCount,2} = 0;
        reportData{loopCount,3} = 0;
        reportData{loopCount,4} = EEG.nbchan;
        reportData{loopCount, end} = outfilename;

        if exclude_badtrials
            pb.Message = 'Removing bad trials';
            btrials = study_GetBadTrials(EEG);
            EEG = pop_rejepoch(EEG, btrials,0);
            %for some reason removing the epochs scrambles the order of the
            %events so now I have to go in and make sure they are correct.
            EEG = wwu_fix_eventmarkers(EEG);
            reportData{loopCount, 2} = length(find(btrials));
        end
        if exclude_badcomps && isfield(EEG, 'icasphere')
            pb.Message = 'Removing bad components';
            bcomps = find(EEG.reject.gcompreject);
            EEG = pop_subcomp(EEG, [],0, 0);
            if isempty(bcomps)
                reportData{loopCount,3} = 0;
            else
                reportData{loopCount,3} = join(num2str(bcomps));
            end
        end
        if interpolate_channels
            %interpolate any channels that are missing from the main
            %channel locations structure.
            %will have to reference again after interpolating
            rtype = EEG.chanlocs(1).ref;
            EEG = eeg_interp(EEG, study.chanlocs);
            if strcmp(rtype, 'average')
                EEG = pop_reref(EEG, []);
            end
            reportData{loopCount,4} = EEG.nbchan;
        end

        %save to a temp file and store the filename
        fcount = fcount + 1;
        [oPath, oFile, oExt] = fileparts(p.filenames{ii,jj});
        subjOutFile = fullfile(oPath, [oFile, '_preave', oExt]);
        %tempfilename = fullfile(outdir, sprintf('%s_%i.tmp',fname,fcount));
        flist{fcount} = subjOutFile;
        wwu_SaveEEGFile(EEG, subjOutFile);

        %

    end
    
pb.Message = 'creating average';
GNDFile = fullfile(outdir, [outfilename, '.GND']);
sets2GND(flist,'out_fname', GNDFile,'verblevel', 3);

%now load the GND file and assign the between subject condition information
GND = load(GNDFile, '-mat');
if isfield(GND, 'GND')
    GND = GND.GND;
end
GND.indiv_conditions = conditions;
save(GNDFile, 'GND', '-mat')
end
parameters.duration = {'Duration (seconds)', toc};
wwu_UpdateProcessLog(study, 'SheetName','average', ...
    'ColumnNames',reportColumnNames, 'RowNames', reportRows,...
    'Values',reportData, 'Parameters',parameters);

close(pb);
delete(h.figure)
