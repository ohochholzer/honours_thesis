% Initial preallocation with an estimated size
maxSize = 1000; 

geoAreaNames = cell(maxSize, 1);
timePeriods = cell(maxSize, 1);
seriesCodes = cell(maxSize, 1);
indicators = cell(maxSize, 1);

% Initialize counters
geoCounter = 0;
timeCounter = 0;
seriesCounter = 0;

% Define the set of repeated indicators
repeated_indicators = ["11.5.1", "11.5.2", "11.b.1", "11.b.2", "12.2.2", "12.8.1", "12.a.1", "12.b.1", "13.1.1", "13.1.2", "13.1.3", "13.3.1", "13.b.1", "15.b.1", "15.c.1", "16.8.1", "16.b.1" ];

% Loop through each goal and process correspdonding excel file 
for i = 1:17
    goal_num = i;
    file_name = strcat('/MATLAB Drive/Goal', string(goal_num), '.xlsx');

    % Read the Excel file into a table
    data = readtable(file_name);

    % Extract unique geographical area names from the data
    uniqueGeoAreaNames = unique(data.GeoAreaName);    
    numNewGeo = length(uniqueGeoAreaNames);          
    geoAreaNames(geoCounter + (1:numNewGeo)) = uniqueGeoAreaNames;  
    geoCounter = geoCounter + numNewGeo;              
    
    % Extract unique time periods from the data
    uniqueTimePeriods = unique(cellstr(string(data.TimePeriod)));   
    numNewTime = length(uniqueTimePeriods);                          
    timePeriods(timeCounter + (1:numNewTime)) = uniqueTimePeriods;   
    timeCounter = timeCounter + numNewTime;                           

    % Loop through each row of the data to create a list of series codes 
    % and their corresponding indicators and goals. This indicator array 
    % will later be used for averaging country scores associated with each 
    % indicator and goal. 
    for row = 1:size(data, 1) 

        seriesCode = data.SeriesCode{row};             
        current_indicator = data.Indicator{row};        

        % Check if the lasy entry is the same as the current series code
        if seriesCounter == 0 || ~strcmp(seriesCodes{seriesCounter}, seriesCode)
            % Increment the counter for series codes
            seriesCounter = seriesCounter + 1;  
            
            % Store the unique series code and corresponding indicator
            seriesCodes{seriesCounter} = seriesCode;     
            indicators{seriesCounter} = current_indicator;       
        end
    end
end

% Trim the preallocated arrays to their actual size
geoAreaNames = geoAreaNames(1:geoCounter);
timePeriods = timePeriods(1:timeCounter);
seriesCodes = seriesCodes(1:seriesCounter);
indicators = indicators(1:seriesCounter);

% Remove duplicate geoAreaNames and timePeriods after processing all files
geoAreaNames = unique(geoAreaNames);
timePeriods = unique(timePeriods);

% Find number of countries, series and years to use as dimensions for the 3D matrix
numGeoAreas = numel(geoAreaNames);
numSeries = numel(seriesCodes); 
numTimePeriods = numel(timePeriods);

% Initialise two 3D matrices 
matrix3D = nan(numGeoAreas, numSeries, numTimePeriods);
matrix3D_repeats = nan(numGeoAreas, numSeries, numTimePeriods); 

% Loop through each goal process correspdonding excel file again
for i = 1:17
    goal_num = i;
    file_name = strcat('/MATLAB Drive/Goal', string(goal_num), '.xlsx');

    % Read the Excel file into a table
    data = readtable(file_name);

    for row = 1:size(data, 1)

        % Find the indices of GeoAreaName and TimePeriod and SeriesCode 
        geoIdx = find(ismember(geoAreaNames, data.GeoAreaName(row)));
        timeIdx = find(ismember(timePeriods, string(data.TimePeriod(row))));
        seriesIdx = find(strcmp(seriesCodes, data.SeriesCode{row}));

        % Check if value is empty 
        if ~isempty(data.Value{row}) && ~isnan(str2double(data.Value{row})) 

        % Filter the goals to retain only the desired values and insert
        % this value into the matrices

            % Goal 1 filter 
            if goal_num == 1
                if (strcmp(data.Sex{row}, 'BOTHSEX') || strcmp(data.Sex{row}, '')) 
                    if (strcmp(data.Location{row}, 'ALLAREA') || strcmp(data.Location{row}, '')) 
                        if (strcmp(data.Age{row}, 'ALLAGE') || strcmp(data.Age{row}, '')) 
                            if (strcmp(data.Quantile{row}, '_T') || strcmp(data.Quantile{row}, ''))
                                value = str2double(data.Value{row});
                                 % If the series appears twice and therefore has 2 indices, only add for the first index so there are no repeats
                                matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                            end 
                        end
                    end 
                end

            % Goal 2 filter
            elseif goal_num == 2
                if ~strcmp(data.Indicator{row}, '2.c.1') 
                    if strcmp(data.Indicator{row}, '2.2.3')
                        if strcmp(data.Sex{row}, 'FEMALE')
                            value = str2double(data.Value{row});
                            matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                        end
                    else 
                        if strcmp(data.Age{row}, '<5Y') || strcmp(data.Age{row}, '15-49') || strcmp(data.Age{row}, 'ALLAGE') || strcmp(data.Age{row}, '')
                            if strcmp(data.Sex{row}, 'BOTHSEX') || strcmp(data.Sex{row}, '')
                                matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                            end
                        end
                    end
                end

            % Goal 3 filter
            elseif goal_num == 3
                if ~strcmp(data.Indicator{row}, '3.7.2') && ~strcmp(data.Indicator{row}, '3.c.1') && ~strcmp(data.SeriesCode{row}, 'SH_DTH_NCD') && ~strcmp(data.Indicator{row}, '3.d.1')
                    if strcmp(data.Indicator{row}, '3.1.1') || strcmp(data.Indicator{row}, '3.7.1')
                        if strcmp(data.Sex{row}, 'FEMALE')
                            value = str2double(data.Value{row});
                            matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                        end
                    elseif strcmp(data.Indicator{row}, '3.3.1')
                        if (strcmp(data.Sex{row}, 'BOTHSEX')) || strcmp(data.Sex{row}, '')
                            if strcmp(data.Age{row}, 'ALLAGE')
                                value = str2double(data.Value{row});
                                matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                            end
                        end
                    else
                        if (strcmp(data.Sex{row}, 'BOTHSEX')) || strcmp(data.Sex{row}, '')
                            if strcmp(data.FootNote{row}, 'TOTAL') || strcmp(data.FootNote{row}, '')
                                value = str2double(data.Value{row});
                                matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                            end
                        end
                    end
                end


            % Goal 4 filter
            elseif goal_num == 4
                if strcmp(data.Indicator{row}, '4.2.1') || strcmp(data.Indicator{row}, '4.2.2') || strcmp(data.Indicator{row}, '4.3.1') || strcmp(data.Indicator{row}, '4.b.1') || strcmp(data.SeriesCode{row}, 'SE_GPI_PART') || strcmp(data.SeriesCode{row}, 'SE_GPI_PTNPRE')
                    if strcmp(data.Sex{row}, 'BOTHSEX') || strcmp(data.Sex{row}, '')
                        if strcmp(data.Age{row}, 'ALLAGE') || strcmp(data.Age{row}, 'M36T59') || strcmp(data.Age{row}, '15-64') || strcmp(data.Age{row}, '')
                            value = str2double(data.Value{row});
                            matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                        end
                    end
                end
            
            %Goal 5 filter
            elseif goal_num == 5
                if ~strcmp(data.Indicator{row}, '5.4.1')
                    if strcmp(data.Indicator{row}, '5.2.1') 
                        if strcmp(data.Age{row}, '15+')
                            value = str2double(data.Value{row});
                            matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                        end
                    elseif strcmp(data.Indicator{row}, '5.b.1')
                        if strcmp(data.Sex{row}, 'BOTHSEX')
                            value = str2double(data.Value{row});
                            matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                        end
                    else
                        if strcmp(data.SeriesCode{row}, 'SG_GEN_PARLNT') || strcmp(data.SeriesCode{row}, 'SP_LGL_LNDAGSEC')
                            if strcmp(data.Sex{row}, 'BOTHSEX')
                                value = str2double(data.Value{row});
                                matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                            end
                        else
                            if strcmp(data.Sex{row}, 'FEMALE') || strcmp(data.Sex{row}, '')
                                value = str2double(data.Value{row});
                                matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                            end
                        end
                    end
                end
            
            %Goal 6 filter
            elseif goal_num == 6
                if  ~strcmp(data.SeriesCode{row}, 'EN_LKW_QLTRB') && ~strcmp(data.SeriesCode{row}, 'EN_LKW_QLTRST')
                    if strcmp(data.SeriesCode{row}, 'ER_H20_PRDU') || strcmp(data.SeriesCode{row}, 'ER_H20_RURP')
                        value = str2double(data.Value{row}); % only RURAl data 
                        matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                        matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                    else
                        if (strcmp(data.Location{row}, 'ALLAREA') || strcmp(data.Location{row}, '')) 
                            if (strcmp(data.Quantile{row}, '_T') || strcmp(data.Quantile{row}, '')) 
                                if (strcmp(data.Activity{row}, '') || strcmp(data.Activity{row}, 'TOTAL'))
                                    value = str2double(data.Value{row});
                                    matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                    matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                                end
                            end
                        end
                    end
                end
            
            %Goal 7 filter
            elseif goal_num == 7
                if (strcmp(data.Location{row}, 'ALLAREA') || strcmp(data.Location{row}, '')) && (strcmp(data.TypeOfRenewableTechnology{row}, '') || strcmp(data.TypeOfRenewableTechnology{row}, 'ALL'))
                    value = str2double(data.Value{row});
                    matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                    matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                end

            %Goal 8 filter
            elseif goal_num == 8
                if strcmp(data.Indicator{row}, "8.6.1") || strcmp(data.Indicator{row}, "8.7.1")
                    if strcmp(data.Sex{row}, 'BOTHSEX')
                        value = str2double(data.Value{row});
                        matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                        matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                    end
                else
                    if (strcmp(data.Location{row}, 'ALLAREA') || strcmp(data.Location{row}, '')) 
                        if (strcmp(data.Sex{row}, 'BOTHSEX') || strcmp(data.Sex{row}, '')) 
                            if (strcmp(data.TypeOfOccupation{row}, '_T') || strcmp(data.TypeOfOccupation{row}, '')) 
                                if (strcmp(data.MigratoryStatus{row}, '_T') || strcmp(data.MigratoryStatus{row}, ''))
                                    if strcmp(data.Age{row}, '') || strcmp(data.Age{row}, '15+') || strcmp(data.Age{row}, 'ALLAGE')
                                        if strcmp(data.EducationLevel{row}, '') || strcmp(data.EducationLevel{row}, '_T')
                                            if strcmp(data.Quantile{row}, '_T') || strcmp(data.Quantile{row}, '')
                                                if strcmp(data.DisabilityStatus{row}, '') || strcmp(data.DisabilityStatus{row}, '_T')
                                                    if strcmp(data.Activity{row}, 'TOTAL') || strcmp(data.Activity{row}, '')
                                                        if strcmp(data.TypeOfProduct{row}, 'ALP') || strcmp(data.TypeOfProduct{row}, '')
                                                            value = str2double(data.Value{row});
                                                            matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

            %Goal 9 filter
            elseif goal_num == 9
                if strcmp(data.SeriesCode{row}, 'EN_ATM_CO2')
                    if strcmp(data.Activity{row}, 'TOTAL') 
                        value = str2double(data.Value{row});
                        matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                        matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                    end
                else
                    value = str2double(data.Value{row});
                    matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                    matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                end

            %Goal 10 filter 
            elseif goal_num == 10
                if ~strcmp(data.Indicator{row}, '10.4.2') && ~strcmp(data.Indicator{row}, '10.6.1')
                    if strcmp(data.Indicator{row}, '10.2.1')
                        value = str2double(data.Value{row});
                        matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                        matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                    else
                        if strcmp(data.Sex{row}, '') || strcmp(data.Sex{row}, 'BOTHSEX')
                            if strcmp(data.Quantile{row}, '_T') || strcmp(data.Quantile{row}, '')
                                if strcmp(data.Location{row}, '') || strcmp(data.Location{row}, 'ALLAREA')
                                    if strcmp(data.GroundsOfDiscrimination{row}, '') || strcmp(data.GroundsOfDiscrimination{row}, 'ALL')
                                        if strcmp(data.PolicyDomains{row}, '') || strcmp(data.PolicyDomains{row}, 'ALLDOMAINS')
                                            if strcmp(data.Counterpart{row}, '') || strcmp(data.Counterpart{row}, '_T')
                                                if strcmp(data.TypeOfProduct{row}, '') || strcmp(data.TypeOfProduct{row}, 'ALP')
                                                    value = str2double(data.Value{row});
                                                    matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                                    matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                                                end 
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

            % Goal 11 filter
            elseif goal_num == 11
                if ~strcmp(data.Indicator{row}, '11.2.1') && ~strcmp(data.Indicator{row}, '11.3.1') && ~strcmp(data.Indicator{row}, '11.6.1') && ~strcmp(data.Indicator{row}, '11.7.1')
                    if strcmp(data.Indicator{row}, '11.1.1')
                        value = str2double(data.Value{row});
                        if ismember(data.Indicator{row}, repeated_indicators)
                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                        else
                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                            matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                        end
                    else
                        if strcmp(data.Level_of_government{row}, '') || strcmp(data.Level_of_government{row}, '_T')
                            if strcmp(data.Location{row}, '') || strcmp(data.Location{row}, 'ALLAREA')
                                if strcmp(data.Sex{row}, '') || strcmp(data.Sex{row}, 'BOTHSEX')
                                    value = str2double(data.Value{row});
                                    if ismember(data.Indicator{row}, repeated_indicators)
                                        matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                                    else
                                        matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                                        matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                    end
                                end
                            end
                        end
                    end
                end

            % Goal 12 filter
            elseif goal_num == 12
                if ~strcmp(data.Indicator{row}, '12.7.1') && ~strcmp(data.SeriesCode{row}, 'SG_SCP_POLINS') && ~strcmp(data.SeriesCode{row}, 'EN_HAZ_TREATV') && ~strcmp(data.SeriesCode{row}, 'EN_MWT_TREATR')
                    if strcmp(data.FoodWasteSector{row}, '') || strcmp(data.FoodWasteSector{row}, 'ALL')
                        if strcmp(data.Activity{row}, '') || strcmp(data.Activity{row}, 'TOTAL')
                            if strcmp(data.LevelOfRequirement{row}, '') || strcmp(data.LevelOfRequirement{row}, 'TOTAL')
                                if strcmp(data.TypeOfRenewableTechnology{row}, '') || strcmp(data.TypeOfRenewableTechnology{row}, 'ALL')
                                    if strcmp(data.TypeOfProduct{row}, '') || strcmp(data.TypeOfProduct{row}, 'ALP')
                                        value = str2double(data.Value{row});
                                        if ismember(data.Indicator{row}, repeated_indicators)
                                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                                        else
                                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                                            matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

            % Goal 13 filter 
            elseif goal_num == 13
                value = str2double(data.Value{row});
                if ismember(data.Indicator{row}, repeated_indicators)
                    matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                else
                    matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                    matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                end

            % Goal 14 filter 
            elseif goal_num == 14
                if ~strcmp(data.Indicator{row}, '14.3.1') && ~strcmp(data.SeriesCode{row}, 'EN_MAR_CHLANM')
                    if strcmp(data.Counterpart{row}, '') || strcmp(data.Counterpart{row}, '_T')
                        if strcmp(data.FrequencyOfChlorophyll_aConcentration{row}, "Extreme") || strcmp(data.FrequencyOfChlorophyll_aConcentration{row}, "")
                            value = str2double(data.Value{row});
                            matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                        end
                    end
                end
            
            % Goal 15 filter 
            elseif goal_num == 15
                if ~strcmp(data.SeriesCode{row}, 'ER_MTN_GRNCOV') && ~strcmp(data.SeriesCode{row}, 'ER_MTN_GRNCVI')
                    if strcmp(data.BioclimaticBelt{row}, '') || strcmp(data.BioclimaticBelt{row}, 'TOTAL')
                        if strcmp(data.Level_Status{row}, '') || strcmp(data.Level_Status{row}, '_T')
                            value = str2double(data.Value{row});
                            if ismember(data.Indicator{row}, repeated_indicators)
                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                            else
                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                                matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                            end
                        end
                    end
                end

            % Goal 16 filter 
            elseif goal_num == 16
                not_included_series = ["SP_PSR_SATIS_GOV", "SP_PSR_SATIS_HLTH", "SP_PSR_SATIS_PRM", "SP_PSR_SATIS_SEC", "SG_DMK_JDC", "SG_DMK_JDC_CNS", "SG_DMK_JDC_HGR", "SG_DMK_JDC_LWR", "SG_DMK_PARLCC_JC", "SG_DMK_PARLCC_LC", "SG_DMK_PARLCC_UC", "SG_DMK_PARLSP_LC", "SG_DMK_PARLSP_UC"];
                youth_only_series = ["SG_DMK_PARLYN_LC", "SG_DMK_PARLYN_UC", "SG_DMK_PARLYP_LC", "SG_DMK_PARLYP_UC", "SG_DMK_PARLYR_LC", "SG_DMK_PARLYR_UC"];
                if ~ismember(data.SeriesCode{row}, not_included_series) && ~strcmp(data.Indicator{row}, '16.8.1')
                    if ismember(data.SeriesCode{row}, youth_only_series)
                        value = str2double(data.Value{row});
                        if ismember(data.Indicator{row}, repeated_indicators)
                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                        else
                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                            matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                        end
                    elseif strcmp(data.Indicator{row}, "16.9.1")
                        if strcmp(data.Age{row}, '<5Y')
                            value = str2double(data.Value{row});
                            if ismember(data.Indicator{row}, repeated_indicators)
                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                            else
                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                                matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                            end
                        end
                    elseif strcmp(data.Indicator{row}, "16.6.1")
                        value = abs(100-str2double(data.Value{row}));
                        if ismember(data.Indicator{row}, repeated_indicators)
                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                        else
                            matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                            matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                        end
                    else
                        if strcmp(data.Sex{row}, '') || strcmp(data.Sex{row}, 'BOTHSEX')
                            if strcmp(data.Location{row}, '') || strcmp(data.Location{row}, 'ALLAREA')
                                if strcmp(data.Age{row}, '') || strcmp(data.Age{row}, 'ALLAGE')
                                    if strcmp(data.CauseOfDeath{row}, '') || strcmp(data.CauseOfDeath{row}, '_T')
                                        if strcmp(data.DisabilityStatus{row}, '') || strcmp(data.DisabilityStatus{row}, '_T')
                                            if strcmp(data.PopulationGroup{row}, '') || strcmp(data.PopulationGroup{row}, 'TOTAL')
                                                if strcmp(data.TypeOfOccupation{row}, '') || strcmp(data.TypeOfOccupation{row}, 'TOTAL_PSP')
                                                    if strcmp(data.EducationLevel{row}, '') || strcmp(data.EducationLevel{row}, '_T')
                                                        if strcmp(data.GroundsOfDiscrimination{row}, '') || strcmp(data.GroundsOfDiscrimination{row}, 'ALL')
                                                            value = abs(100-str2double(data.Value{row}));
                                                            if ismember(data.Indicator{row}, repeated_indicators)
                                                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                                                            else
                                                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                                                                matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

            % Goal 17 filter 
            elseif goal_num == 17
                if strcmp(data.Sex{row}, '') || strcmp(data.Sex{row}, 'BOTHSEX')
                    if strcmp(data.TypeOfProduct{row}, '') || strcmp(data.TypeOfProduct{row}, 'ALP')
                        if strcmp(data.Activity{row}, '') || strcmp(data.Activity{row}, 'TOTAL')
                            if strcmp(data.TypeOfSpeed{row}, '') || strcmp(data.TypeOfSpeed{row}, 'ANYS')
                                value = str2double(data.Value{row});
                                matrix3D(geoIdx, seriesIdx(1), timeIdx) = value;
                                matrix3D_repeats(geoIdx, seriesIdx, timeIdx) = value;
                            end
                        end
                    end
                end
            end    
        end
    end
end


