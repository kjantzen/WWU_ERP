function [study, not_saved] = study_SaveStudy(study, varargin)
%study = study_SaveStudy(study, 'saveas', [0,1]);
%writes a new study file or saves an existing study file to the STUDIES folder
%all studies are saved to the STUDIES folder in the path specified by the
%study_GetEEGPath function.
%
%Inputs:
%       study:   A HCND_EEG study structure to save
%Optional
%       'saveas':  a 1 indicates that the study structure will be saved
%       with a new study name.  When a 0 is passed the existing study will 
%       be overwritten with the new information.  The default is 0
%Output
%       study:  the saved study structure
%

p = wwu_finputcheck(varargin, {...
        'saveas', 'integer', [0,1], [0];...
         });

not_saved = 0;
EEGPath = study_GetEEGPath;

STUDYPATH = fullfile(EEGPath, 'STUDIES');
if isempty(dir(STUDYPATH))
    mkdir(EEGPath, 'STUDIES');
end

if isempty(study.filename) || p.saveas==1
    
    dp.title = 'Save Study';
    dp.msg = 'Enter a name for saving this study';
    dp.options = {'OK', 'Cancel'};
    op = wwu_inputdlg(dp);
    if isempty(op.input) || contains(op.option, 'Cancel')
        fprintf('No valid file or the user clicked Cancel\n');
        not_saved = 1;
        return
    end

    fsname = fullfile(STUDYPATH, [op.input, '.study']);
    if ~ isempty(dir(fsname))
        btn = questdlg(sprintf('The STUDY %s exists.\nDo you want to overwrite?', op.input), 'Overwrite Request', 'yes', 'no', 'no');
        if strcmp(btn, 'no')
            not_saved = 1;
            return
        end     
    end
    study.filename = [op.input, '.study'];
    if isempty(study.name)
        study.name = op.input;
    end
end
savefile = fullfile(STUDYPATH, study.filename);
save(savefile, 'study', '-mat');



