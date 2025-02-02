%study_PlotANOVAresults(r)
%   plots the results of an GLM test based on the information in the 
%   structure r
%
% r should be a statistics structure passed from an ERP bin file created
% within the esma environment
%
function study_PlotANOVAresults(r)

if nargin < 1
    msg = 'A statistics structure must be passed in the call to study_PlotANOVAresults';
    error('%s\nThis function should not be called directly.', msg);
end

r = arrangeData(r);
scheme = eeg_LoadScheme;
[H, W, L,B] = setFigureSizeAndPosition(scheme);


h.figure = uifigure('Position', [L, B, W, H],...
    'Color', scheme.Window.BackgroundColor.Value);

h.grid = uigridlayout('Parent', h.figure,...
    'RowHeight', {'1x', 20, '1x', 20, '2x'}, ...
    'ColumnWidth', {'1x','1x'}, 'Scrollable', 'on',...
    'BackgroundColor',scheme.Window.BackgroundColor.Value);

h.tree_info = uitree('Parent', h.grid,...
    'BackgroundColor', scheme.Window.BackgroundColor.Value, ...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);
h.tree_info.Layout.Row = 1;
h.tree_info.Layout.Column = 1;

h.label_desc = uilabel('Parent', h.grid,'Text', 'Descriptives',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);
h.label_desc.Layout.Row = 2;
h.label_desc.Layout.Column = 1;

h.label_source = uilabel('Parent', h.grid,'Text', 'Source Table',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);
h.label_source.Layout.Row = 4;
h.label_source.Layout.Column = 1;

h.desctable = uitable('Parent', h.grid);
h.desctable.Layout.Row = 3;
h.desctable.Layout.Column = 1;

h.sourcetable = uitable('Parent', h.grid);
h.sourcetable.Layout.Row = 5;
h.sourcetable.Layout.Column = 1;


h.axis_bar = uiaxes('Parent', h.grid, ...
    'Color', scheme.Axis.BackgroundColor.Value,...
    'XColor', scheme.Axis.AxisColor.Value,...
    'YColor', scheme.Axis.AxisColor.Value,...
    'FontName', scheme.Axis.Font.Value);
h.axis_bar.Layout.Row = [2,5];
h.axis_bar.Layout.Column = 2;
drawnow nocallbacks;

h.panel = uipanel('Parent', h.grid, 'Title', 'Legend',...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value,...
    'BorderType','none',...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor',scheme.Panel.FontColor.Value,...
    'Scrollable','on');
h.panel.Layout.Row = 1;
h.panel.Layout.Column = 2;

uilabel('Parent', h.panel,...
    'Position', [10, 300, 130, 20],...
    'Text', 'Factor on x-axis',...
    'FontColor',scheme.Label.FontColor.Value);

h.dropdown_xaxis = uidropdown('Parent', h.panel,...
    'Position', [10, 280, 130, 20], ...
    'Items', r.factors, 'ItemsData', 1:length(r.factors),...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontName',scheme.Dropdown.Font.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);

h.axis_legend = uiaxes('Parent', h.panel,...
    'Position', [0,0,400,280],...
    'Color', scheme.Panel.BackgroundColor.Value,...
    'XTick', [],...
    'YTick', [],...
    'Box', 'off',...
    'XColor',scheme.Axis.AxisColor.Value,...
    'YColor', scheme.Axis.AxisColor.Value,...
    'Interactions',[]);
h.axis_legend.Toolbar.Visible = 'off';

%populate the tree object with information about the test
uitreenode('Parent', h.tree_info,...
    'Text', sprintf('Measurement:\t\t%s',r.type));

n = uitreenode('Parent', h.tree_info,...
    'Text', 'Factors');
for ii = 1:length(r.factors)
    uitreenode('Parent', n,...
        'Text', sprintf('%s (%s)', r.factors{ii}, r.levels{ii}));
end
n = uitreenode('Parent', h.tree_info,...
    'Text', 'Conditions');
for ii = 1:length(r.conditions)
    uitreenode('Parent', n,'Text', r.conditions{ii});
end
uitreenode('Parent', h.tree_info, ...
    'Text', sprintf('\nTime window:\t\t%5.2fms to %5.2fms\n', r.timewindow(1), r.timewindow(2)));
uitreenode('Parent', h.tree_info,...
    'Text', sprintf('Time points:\t\tsample %i to sample %i\n', r.pntwindow(1), r.pntwindow(2)));
n = uitreenode('Parent', h.tree_info,...
    'Text', 'Channels');
chans_used = unique(r.chans_used);
for ii = 1:length(chans_used)
    uitreenode('Parent', n, 'Text', chans_used{ii});
end

%display means and standard deviations
d = r.within;

%add a column that holds the name of the file associated with each
%condition
if contains(r.factors{end}, 'Channel')
    %if there are channels we have to do this once for each channel
    r.has_chans = true;
    r.nchan = str2double(r.levels{end});
    r.nfactors = length(r.factors) -1;
    d.Conditions = repmat(r.conditions', r.nchan,1);
    d.Channel = r.chans_used';
%    d = movevars(d, 'Channel', 'Before', d.Properties.VariableNames{1}); 
else
    %if not, once is enough
    r.has_chans = false;
    r.nfactors = length(r.factors);
    d.Conditions = r.conditions';
end


%%
%[nsubj, ncond] = size(r.data); 
%nd = reshape(r.data.Variables, 1, nsubj * ncond)';
%for ii = 1:length(r.factors)
    %v = reshape(repmat(r.Within.[r.factors{ii}], 5, 1), 1, nubj * ncond)
%end
d = movevars(d, 'Conditions', 'Before', d.Properties.VariableNames{1});
d.Mean = num2cell(d.Mean);
d.StdDev = num2cell(std(r.data.Variables)');

h.desctable.Data = d{:,:};
h.desctable.ColumnName = d.Properties.VariableNames;
h.desctable.RowName = d.Properties.RowNames;

s = r.source_table;
sd = cellfun(@(x) num2str(x,3), num2cell(s.Variables), 'UniformOutput', false);
rows_to_change = contains(s.Properties.RowNames, 'Error');
if sum(rows_to_change)> 0
    sd(rows_to_change,4:end) = {''};
end
h.sourcetable.Data = sd;
h.sourcetable.ColumnName = s.Properties.VariableNames;
s.Properties.RowNames = strrep(s.Properties.RowNames, '(Intercept):','');
s.Properties.RowNames = strrep(s.Properties.RowNames, ':','*');
h.sourcetable.RowName = s.Properties.RowNames;

h.scheme = scheme;
h.dropdown_xaxis.ValueChangedFcn = {@callback_createplots, r, h};
callback_createplots([],[],r,h)

%**************************************************************************
function callback_createplots(hObject, event, r, h)
%makes plots - the current thinking is to make one for each channel'

%this is teh maximum # of factors that can be uniquely plotted.  More can
%be plotted, but they will not have unique symbols, colors, etc.
%this does not include the factor plotted on the xaxis
MAX_FACTORS = 4; 
SPREAD_WIDTH = .25;

%use these to cycle through different plot types
plot_fillcolor = lines;
plot_symbol = {'o', 'd', 's', 'p', 'h', '+', '*', 'x'};
plot_linecolor = {'w', 'w', 'w', 'w', 'w', 'w', 'w'};

plot_symbol_size = {80, 100, 120, 140, 160, 180};

avedata = mean(r.data{:,:})';
stderr = std(r.data{:,:})'./ sqrt(size(r.data,1));

%get the factor to plot on the x-axis
xaxis_var = h.dropdown_xaxis.Value;
[~, id, ~] = unique(r.within{:,xaxis_var});
names = r.within{sort(id), xaxis_var};

xaxis_values = r.level_matrix(:,xaxis_var);

%now get the information about the other factors after removing the one to
%plot on the xaxis
a = ones(size(r.levels));
a(xaxis_var) = 0;
rlm = r.level_matrix(:,a==1);
rcm = r.within(:,a==1);
rl = cellfun(@str2num, r.levels(a==1));
rf = r.factors(a==1);

offset = SPREAD_WIDTH/prod(rl);

if r.nfactors < MAX_FACTORS
    a = ones(size(r.level_matrix,1), MAX_FACTORS - r.nfactors+1);
    rlm = [rlm, a];
end

cla(h.axis_bar)
xcount = zeros(str2double(r.levels{xaxis_var}),1);

for ii = 1:length(xaxis_values)
            
            xcount(xaxis_values(ii)) = xcount(xaxis_values(ii)) + 1;
            xpos = xcount(xaxis_values(ii)) * offset - (SPREAD_WIDTH/2) + xaxis_values(ii);
            s = scatter(xpos, avedata(ii), 'Parent',h.axis_bar,...
                'Marker', plot_symbol{rlm(ii,2)},...
                'MarkerFaceColor', plot_fillcolor(rlm(ii,1),:),...
                'MarkerEdgeColor', plot_linecolor{rlm(ii,3)},...
                'SizeData', plot_symbol_size{rlm(ii,4)},...
                'LineWidth', 1.5,...
                'MarkerFaceAlpha', 1);
            
            line(h.axis_bar, [xpos,xpos],...
                [avedata(ii) - stderr(ii), avedata(ii) + stderr(ii)], ...
                'linewidth', .5, 'color', 'w')
            
                hold(h.axis_bar,  'on');
end
h.axis_bar.XLim = [.5, max(xaxis_values)+.5];
h.axis_bar.XLabel.String = r.factors{xaxis_var};
h.axis_bar.XTick = 1:1:max(xaxis_values);
h.axis_bar.XTickLabel  = names;
h.axis_bar.YLabel.String = r.type;
h.axis_bar.XGrid = 'on';
h.axis_bar.YGrid = 'on';

%%% make the box plot%

% plot the legend
hold(h.axis_legend, 'off');
cla(h.axis_legend);
hold(h.axis_legend, 'on');

ypos = .9;

for ii = 1:length(rf)
  
    text(h.axis_legend, .1, ypos, rf{ii}, 'Color', 'w');
    [~,ia, ~] = unique(rcm(:,ii));
    lnames = rcm(sort(ia),ii);
   
    ypos = ypos - .06;
    
    ps = plot_symbol{1};
    fc = h.figure.Color;
    lc = plot_linecolor{1};
    ss = plot_symbol_size{1};
    
    
    for jj = 1:rl(ii)
        if ii == 1
            fc = plot_fillcolor(jj,:);
        elseif ii ==2
            ps = plot_symbol{jj};
        elseif ii ==3
            lc = plot_linecolor{jj};
        elseif ii == 4
            ss = plot_symbol_size{jj};
        else
            break
        end       
        scatter(h.axis_legend, .2,ypos, 'Marker', ps,'MarkerFaceColor', fc,'MarkerEdgeColor', lc, 'SizeData', ss, 'LineWidth', 1.5);
        text(h.axis_legend, .3, ypos,  lnames{jj,1}, 'Color', h.scheme.Axis.AxisColor.Value);
        ypos  = ypos - .06;
        
    end
    ypos = ypos - .1;
end

%if ypos > 50; ypos = 50; end
h.axis_legend.XLim = [0, 1];
h.axis_legend.YLim = [0, 1];

%*************************************************************************
function rNew = arrangeData(r)
%right now this function is only removing the columns for the between
%subject variable because it interferes with the current plotting method
%in future, it will organize the data to allow for plotting of both between
%and within variables.

    rNew = r;
    if r.hasBetween
        %find out how many between variables there are
        nBetween = size(r.betweenVars,2);

        %strip off the between columns that were necessary for running the
        %stats. The betweencondition data still in the r.betweenVars
        %variable
        rNew.data = removevars(rNew.data,1:nBetween);

    end

%*************************************************************************
function [H,W,L,B] =  setFigureSizeAndPosition(scheme)

    if scheme.ScreenHeight < 1080
        H= scheme.ScreenHeight;
    else
        H = 1080;
    end
    if scheme.ScreenWidth < 1000
        W = scheme.ScreenWidth;
    else
        W = 1000;
    end
    L = (scheme.ScreenWidth - W) /2;
    B = (scheme.ScreenHeight - H)/2;
