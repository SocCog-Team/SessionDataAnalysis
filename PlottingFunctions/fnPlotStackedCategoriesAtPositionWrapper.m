function [] = fnPlotStackedCategoriesAtPositionWrapper( PositionLabel, StackHeightToInitialPLotHeightRatio, StackedXData, y_lim, StackedColors, StackedTransparencies )
y_height = (y_lim(2) - y_lim(1));
num_stacked_items = size(StackedXData, 1);
new_y_lim = y_lim;

switch PositionLabel
	case 'StackedOnTop'
		% make room for the category markers on top of the existing plot
		y_increment_per_stack = y_height * StackHeightToInitialPLotHeightRatio / (num_stacked_items + 1);
		new_y_lim = [y_lim(1), (y_lim(2) + (StackHeightToInitialPLotHeightRatio) * y_height)];
		set(gca(), 'YLim', new_y_lim);
		
	case 'StackedOnBottom'
		% make room for the category markers below the existing plot
		y_increment_per_stack = y_height * StackHeightToInitialPLotHeightRatio / (num_stacked_items + 1);
		new_y_lim = [(y_lim(1) - (StackHeightToInitialPLotHeightRatio) * y_height), y_lim(2)];
		set(gca(), 'YLim', new_y_lim);
		
	case 'StackedBottomToTop'
		% just fill the existing plot area
		y_increment_per_stack = y_height / (num_stacked_items);
		new_y_lim = y_lim;
		
	otherwise
		disp(['Position label: ', PositionLabel, ' not implemented yet, skipping...'])
		return
end


for iStackItem = 1 : num_stacked_items
	CurrentCategoryByXVals = StackedXData{iStackItem};
	CurrentColorByCategoryList = StackedColors{iStackItem};
	CurrentTransparency = StackedTransparencies{iStackItem};
	switch PositionLabel
		case 'StackedOnTop'
			% we want one y_increment as separator from the plots intial YLimits
			CurrentLowY = y_lim(2) + ((iStackItem) * y_increment_per_stack);
			CurrentHighY = CurrentLowY + y_increment_per_stack;
			
		case 'StackedOnBottom'
			% we want one y_increment as separator from the plots intial YLimits
			CurrentLowY = new_y_lim(1) + ((iStackItem - 1) * y_increment_per_stack);
			CurrentHighY = CurrentLowY + y_increment_per_stack;
			
		case 'StackedBottomToTop'
			% we want one y_increment as separator from the plots intial
			% YLimits
			CurrentLowY = y_lim(1) + ((iStackItem - 1) * y_increment_per_stack);
			CurrentHighY = CurrentLowY + y_increment_per_stack;
	end
	% now plot
	fnPlotBackgroundByCategory(CurrentCategoryByXVals, [CurrentLowY, CurrentHighY], CurrentColorByCategoryList, CurrentTransparency);
end

return
end
