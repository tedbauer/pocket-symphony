port module DrumMachine exposing (Model, Msg(..), init, update, view)

import Array
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onMouseDown)
import Platform.Cmd as Cmd


type alias Model =
    { activeCol : Int
    , cells : Array.Array DrumColumn
    }


type DrumCellState
    = CellEnabled
    | CellDisabled


type alias DrumColumn =
    Array.Array DrumCellState



-- MODEL


init : Model
init =
    { activeCol = 0
    , cells = Array.repeat 16 (Array.repeat 3 CellDisabled)
    }



-- VIEW


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


isColActive : Int -> Model -> Bool
isColActive col model =
    model.activeCol == col


patternCol : Model -> Int -> Html Msg
patternCol model columnNumber =
    div
        [ class "drumcol"
        , attribute "data-on"
            (if isColActive columnNumber model then
                "true"

             else
                "false"
            )
        ]
        [ div
            [ class "drumcell"
            , onMouseDown (ToggleDrumCell columnNumber 0)
            , attribute "data-enabled"
                (if isDrumCellPopulated model columnNumber 0 then
                    "true"

                 else
                    "false"
                )
            ]
            []
        , div
            [ class "drumcell"
            , onMouseDown (ToggleDrumCell columnNumber 1)
            , attribute "data-enabled"
                (if isDrumCellPopulated model columnNumber 1 then
                    "true"

                 else
                    "false"
                )
            ]
            []
        , div
            [ class "drumcell"
            , onMouseDown (ToggleDrumCell columnNumber 2)
            , attribute "data-enabled"
                (if isDrumCellPopulated model columnNumber 2 then
                    "true"

                 else
                    "false"
                )
            ]
            []
        ]


drumMachineCard : Model -> Html Msg
drumMachineCard model =
    div [ class "card" ]
        [ div [ class "cardtitle" ]
            [ text "🥁 Drum machine"
            , div [ class "drummachine" ]
                [ div [ class "drumlabels" ] [ div [ class "drumlabel" ] [ text "Kick" ], div [ class "drumlabel" ] [ text "Snare" ], div [ class "drumlabel" ] [ text "Hihat" ] ]
                , div [ class "drumgrid" ]
                    [ patternCol model 0
                    , patternCol model 1
                    , patternCol model 2
                    , patternCol model 3
                    , patternCol model 4
                    , patternCol model 5
                    , patternCol model 6
                    , patternCol model 7
                    , patternCol model 8
                    , patternCol model 9
                    , patternCol model 10
                    , patternCol model 11
                    , patternCol model 12
                    , patternCol model 13
                    , patternCol model 14
                    , patternCol model 15
                    ]
                ]
            ]
        ]


view : Model -> Html Msg
view model =
    drumMachineCard model



-- UPDATE


type Msg
    = ToggleDrumCell Int Int
    | SetCurrentStep Int


flipCellState : DrumCellState -> DrumCellState
flipCellState state =
    case state of
        CellEnabled ->
            CellDisabled

        CellDisabled ->
            CellEnabled


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


updateActiveCol : Int -> Model -> Model
updateActiveCol activeCol model =
    { model | activeCol = activeCol }


numberToDrumType : Int -> String
numberToDrumType number =
    if number == 0 then
        "kick"

    else if number == 1 then
        "snare"

    else
        "hihat"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleDrumCell columnNumber rowNumber ->
            ( toggleDrumCellState model columnNumber rowNumber, toggleDrumPatternAt ( numberToDrumType rowNumber, columnNumber ) )

        SetCurrentStep step ->
            ( updateActiveCol (modBy 16 step) model, Cmd.none )



-- PORTS


port toggleDrumPatternAt : ( String, Int ) -> Cmd msg
