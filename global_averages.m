% Define the countries you want to plot
countries_to_plot = country_names;  % Replace with any name of country or list of multiple countries

% Extract the scores for the selected countries
selected_scores = zeros(length(countries_to_plot), numPeriods);

% Define year periods in reverse order
year_periods = {'2014-2023', '2013-2023', '2012-2023', '2011-2023', '2010-2023', '2009-2023', '2008-2023', '2007-2023', '2006-2023', '2005-2023', '2004-2023'};
x_labels = string(year_periods);

% Loop through each country 
for i = 1:length(countries_to_plot)
    country_name = countries_to_plot{i};
    country_idx = find(strcmp(country_scores_table.Country, country_name)); % Find the index of the current country in the country_scores_table
    
    % Extract score from scores table and store in selected_scores matrix
    if ~isempty(country_idx)
        selected_scores(i, :) = [country_scores_table{country_idx, 3:end}]; 
    end
end

% Initialize a figure
% Set figure properties for consistent size
figure('Units', 'inches', 'Position', [0, 0, 6, 4]);
hold on;

% Loop over each country and plot their scores in grey
for i = 1:length(countries_to_plot)
   if i == 1
       % Plot the first country's scores with a handle for legend display
       plot1 = plot(analysis_periods, selected_scores(i, :), 'Color', [0.8 0.8 0.8], 'DisplayName', "Individual Country Scores");
   else
       plot(analysis_periods, selected_scores(i, :), 'Color', [0.8 0.8 0.8]);
   end
end

% Calculate the average score across all countries for each time period
average_scores = mean(selected_scores, 1, 'omitnan');

% Calculate the standard deviation across all countries
std_deviation = std(selected_scores, 1, 'omitnan');

% Plot the average scores as a thick black line
average = plot(analysis_periods, average_scores, 'k', 'LineWidth', 2, 'DisplayName', 'Global Average'); % Plot with a handle for legend display

% Plot the standard deviation as dotted black lines
std1 = plot(analysis_periods, average_scores + std_deviation, '--k', 'LineWidth', 1, 'DisplayName', '+/- Std Deviation'); % Plot first one with a handle for legend display
plot(analysis_periods, average_scores - std_deviation, '--k', 'LineWidth', 1);

% Add labels and title
xlabel('Analysis Period');
ylabel('Score');
title('Scores of All Countries and Global Average');
set(gca, 'XDir', 'reverse'); % Reverse the x-axis direction

% Adjust the axis to ensure grey lines don't overlap with axes
ax = gca;
ax.Layer = 'top';  

% Add a legend and position it in the best location
legend([plot1, average, std1], 'Location', 'southwest', 'FontSize', 8);

% Set the x-tick labels using the x_labels variable
xticklabels(x_labels); 

% Rotate the x-tick labels 45 degrees
xtickangle(45); 

% Add grid lines for better visualization 
grid on;
hold off;

% Create a row vector for the analysis periods and the average scores
analysis_periods_row = analysis_periods;
average_scores_row = average_scores;

% Combine the periods and scores into a matrix
landscape_data = [analysis_periods_row; average_scores_row];

% Convert the matrix to a table with appropriate row and column names
global_averages_table = array2table(landscape_data, 'RowNames', {'Analysis Period', 'Average Scores'});

% Set the column names as empty if you don't need them, or create a numeric series
global_averages_table.Properties.VariableNames = strcat('Var', string(1:length(analysis_periods)));

% Save table into another sheet in excel file
writetable(global_averages_table, excelFilename, 'Sheet', 'Global Averages');





