function handleStruct = normalizeUicontrolFields(handleStruct)
     %the added Position and removal is to bypass a warning that pops because
    %Matalb does not like the units field to follow the position field when
    %initializing a uicontrol- notice that the copy is a lower case and thus
    %different than the upper-cased Position name
    handleStruct = rmfield(handleStruct,'Type');
    handleStruct = rmfield(handleStruct,'Extent');
    handleStruct = rmfield(handleStruct,'BeingDeleted');
    handleStruct.position = handleStruct.Position;
    handleStruct = rmfield(handleStruct,'Position');
end