module DrumMachine exposing (Model, initDrumMachineModel, isColActive, isDrumCellPopulated, numberToDrumType, toggleDrumCellState, updateActiveCol)

import Array


type alias Model =
    { activeCol : Int
    , cells : Array.Array DrumColumn
    }


type alias DrumColumn =
    Array.Array DrumCellState


type DrumCellState
    = CellEnabled
    | CellDisabled


isColActive : Int -> Model -> Bool
isColActive col model =
    model.activeCol == col


updateActiveCol : Int -> Model -> Model
updateActiveCol activeCol model =
    { model | activeCol = activeCol }


initDrumMachineModel : Model
initDrumMachineModel =
    { activeCol = 0
    , cells = Array.repeat 16 (Array.repeat 3 CellDisabled)
    }


flipCellState : DrumCellState -> DrumCellState
flipCellState state =
    case state of
        CellEnabled ->
            CellDisabled

        CellDisabled ->
            CellEnabled


isDrumCellPopulated : Model -> Int -> Int -> Bool
isDrumCellPopulated model columnNumber rowNumber =
    case Array.get columnNumber model.cells of
        Maybe.Just column ->
            case Array.get rowNumber column of
                Maybe.Just CellEnabled ->
                    True

                Maybe.Just CellDisabled ->
                    False

                Maybe.Nothing ->
                    False

        Maybe.Nothing ->
            False


toggleDrumCellState : Model -> Int -> Int -> Model
toggleDrumCellState model columnNumber rowNumber =
    case Array.get columnNumber model.cells of
        Maybe.Just column ->
            case Array.get rowNumber column of
                Maybe.Just prevCellState ->
                    let
                        updatedColumn =
                            Array.set rowNumber (flipCellState prevCellState) column
                    in
                    let
                        updatedCells =
                            Array.set columnNumber updatedColumn model.cells
                    in
                    let
                        updatedModel =
                            { model | cells = updatedCells }
                    in
                    updatedModel

                Maybe.Nothing ->
                    model

        Maybe.Nothing ->
            model


numberToDrumType : Int -> String
numberToDrumType number =
    if number == 0 then
        "kick"

    else if number == 1 then
        "snare"

    else
        "hihat"
