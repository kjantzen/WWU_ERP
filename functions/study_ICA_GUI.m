%study_ICA_GUI() - GUI for batch computing ICA on a set of files
%
%Usage:
%>> study_ICA_GUI(filenames);
%
%Required Inputs:
%   filenames   -   a cell array of filenames to on which to compute ICA.

% Update 5/13/20 KJ Jantzen
function h = study_ICA_GUI(study, filenames)

scheme = eeg_LoadScheme;
W = 450; H = 200;
figpos = [(scheme.ScreenWidth-W)/2,(scheme.ScreenHeight-H)/2, W, H];
%setup the main figure window

handles.figure = uifigure(...
    'Color', scheme.Window.BackgroundColor.Value,...
    'Position', figpos,...
    'NumberTitle', 'off',...
    'Menubar', 'none',...
    'WindowStyle', 'modal');

h = handles.figure;

handles.uipanel1 = uipanel(...
    'Parent', handles.figure,...
    'Title','ICA options',...
    'Position',[10, 35, 430, 160],...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value,...
    'HighlightColor',scheme.Panel.FontColor.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize',scheme.Panel.FontSize.Value);
%*************************************************************************
handles.check_nobad = uicheckbox(...
    'Parent', handles.uipanel1, ...
    'Text', 'Remove bad trials?',...
    'value', 1,....
    'Position', [20, 105, 250, 20],...
    'FontName',scheme.Checkbox.Font.Value,...
    'FontColor',scheme.Checkbox.FontColor.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value);

handles.check_overwrite = uicheckbox(...
    'Parent', handles.uipanel1, ...
    'Text', 'Overwrite Existing Components?',...
    'value', 1,....
    'Position', [20, 75, 250, 20],...
        'FontName',scheme.Checkbox.Font.Value,...
    'FontColor',scheme.Checkbox.FontColor.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value);

handles.check_filter = uicheckbox(...
    'Parent', handles.uipanel1, ...
    'text', 'Apply a band pass filter running ICA?',...
    'Value',1,...
    'Position', [20, 45, 250, 20],...
    'FontName',scheme.Checkbox.Font.Value,...
    'FontColor',scheme.Checkbox.FontColor.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value);

handles.edit_filtlow = uieditfield(...
    handles.uipanel1, 'numeric',...
    'Value', 1,...
    'BackGroundColor', scheme.Edit.BackgroundColor.Value, ...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'Position', [175, 10, 60, 20],...
    'Limits', [0, 50], ...
    'RoundFractionalValues', 'on',...
    'ValueDisplayFormat', '%i Hz');

handles.edit_filthigh = uieditfield(...
    handles.uipanel1, 'numeric',...
    'Value', 50,...
    'BackGroundColor', scheme.Edit.BackgroundColor.Value, ...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'Position', [245, 10, 100, 20],...
    'Limits', [0, 500], ...
    'RoundFractionalValues', 'on',...
    'ValueDisplayFormat', '%i Hz');

uilabel('Parent', handles.uipanel1, ...
    'text', 'filter edges (low/high)',...
    'HorizontalAlignment', 'left', ...
    'Position', [20, 10, 150, 20],...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor',scheme.Label.FontColor.Value);

handles.button_compute = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Compute ICA',...
    'Position', [W-110, 5, 100, 25],...
    'BackgroundColor',scheme.Button.BackgroundColor.Value,...
    'FontColor',scheme.Button.FontColor.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'FontName', scheme.Button.Font.Value);

handles.button_cancel = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Cancel',...
    'Position', [W-200, 5, 80, 25],...
    'BackgroundColor',scheme.Button.BackgroundColor.Value,...
    'FontColor',scheme.Button.FontColor.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'FontName', scheme.Button.Font.Value);

handles.button_compute.ButtonPushedFcn = {@callback_ComputeICA, handles, study, filenames};
handles.button_cancel.ButtonPushedFcn = {@callback_cancel, handles};

%**********************************************
function callback_cancel(~,~, h)
    close(h.figure)
   
%**********************************************
function callback_ComputeICA  (src, eventdata, h,study, fnames)

tic
Excludebad = h.check_nobad.Value;
FiltData = h.check_filter.Value;
OverWrite = h.check_overwrite.Value;

parameters.operation = {'Operation', 'Compute ICA'};
parameters.date = {'Date and time', datetime("now")};
parameters.algorithm = {'Algorith', 'acssobiro'};
parameters.exclude = {"Exclude bad trials", Excludebad};
parameters.filter = {'Filter first', FiltData};

if FiltData
    filtlow = h.edit_filtlow.Value;
    filthigh = h.edit_filthigh.Value;
    if filtlow >= filthigh && filthigh ~=0
        uialert(h.figure, 'The low edge of the filter must be less than the high edge', 'Filter error');
        return
    end
    parameters.low = {'FIlter low edge', filtlow};
    parameters.high = {'FIlter high edge', filthigh};
end
pb = uiprogressdlg(h.figure, 'Message', 'computing the ICA for each particpant will take some time', 'Title', 'Compute ICA', 'ShowPercentage', 'on');

reportValues = cell(length(fnames), 2);
reportColumnNames = {'Written to file', 'N Trials Removed'};
%loop through each subject in the study
for jj = 1:length(fnames)
    
    [fpath, fname, fext] = fileparts(fnames{jj});
    Header = wwu_LoadEEGFile(fnames{jj}, {'icaweights'});
     
    %check if components exist.
    if ~isempty(Header.icaweights) && ~OverWrite
        fprintf('ICA components found.  Skipping this file\n');
        reportValues{jj,1} = false;
        continue;
    else
        reportValues{jj,1} = true;
    end
    
    EEG = wwu_LoadEEGFile(fnames{jj});
    
    %filter the data just for the purpose of PCA, then apply the components
    %to the unfiltered data at the end
    if FiltData
        fprintf('Pre filtering the data\n');
        EEGprocessed = pop_eegfiltnew(EEG, 'locutoff', filtlow, 'hicutoff', filthigh, 'revfilt', 0);
    else
        EEGprocessed = EEG;
    end
    
    %compute the IC's
    fprintf('computing Independent components\n\n');
    
    %compute the rank of the data and subtract 1 because we have computed the
    %average reference.  The rank function does not seem to detect this
    %decrease in the rank of data so we compensate manually
    dv = size(EEGprocessed.data);
    pcacomp = (dv(1));
    
    %keeping this in even though there is no option to reduce ICA dimensionality
    %when calling the sobi algorithm via the pop_runica function
    if pcacomp==EEG.nbchan && (strcmp(EEG.ref,'averef') || strcmp(EEG.ref, 'average'))
        pcacomp = pcacomp - 1;
        fprintf('Matlab computed full rank so reducing by 1 for the average reference\n');
    end
    if  isfield(EEGprocessed, 'chaninfo') && isfield(EEGprocessed.chaninfo, 'removedchans')
        if ~isempty(EEGprocessed.chaninfo.removedchans)
            pcacomp = pcacomp - length(EEGprocessed.chaninfo.removedchans);
            fprintf('Reducing rank to accouunt for removed channels\n')
        end
    end
    if Excludebad
        bad_trials = study_GetBadTrials(EEGprocessed);
        EEGprocessed = pop_rejepoch(EEGprocessed, bad_trials, 0);
        reportValues{jj,2} = sum(bad_trials);
    else
        reportValues{jj,2} = 0;
    end 
  
   fprintf('hcnd_eeg says the rank of this data is %i\n', pcacomp);
  % if EEGprocessed.trials == 1
  %     fprintf('Detected continuous data so running sobi algorithm because it is blazing fast.\n')
  %      EEGOut = pop_runica(EEGprocessed, 'icatype', 'sobi', 'concatenate', 'off', 'n', pcacomp);
  % else
  %      fprintf('Detected epoched data so running the acsobiro algorithm for epoched data'\n);
    fprintf('calling the sobi algorithm which uses the data full rank')
    
    EEGprocessed = pop_runica(EEGprocessed, 'icatype', 'acsobiro', 'concatenate', 'off');
    EEG.icaweights = EEGprocessed.icaweights;
    EEG.icasphere = EEGprocessed.icasphere;
    EEG.icaact = EEGprocessed.icaact;
    EEG.icachansind = EEGprocessed.icachansind;
 %  end

  wwu_SaveEEGFile(EEG, fnames{jj});
  clear EEGIn EEGOut EEGProcessed
  pb.Value = jj/length(fnames);
  
end
parameters.duration = {'Duration', toc};
wwu_UpdateProcessLog(study,"RowNames",fnames, "ColumnNames",reportColumnNames, ...
    "Parameters",parameters,"SheetName","ICA", "Values",reportValues);
close(pb);
close(h.figure);
