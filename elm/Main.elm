port module Main exposing (..)

import Browser
import ControlBar
import DrumMachine
import Html exposing (..)
import Html.Attributes exposing (..)
import Platform.Cmd as Cmd
import Sequencer


type alias Model =
    { controlBar : ControlBar.Model, sequencer : Sequencer.Model, drumMachine : DrumMachine.Model, activeChord : Int, playing : Bool, bpm : Int }



-- MODEL


init : () -> ( Model, Cmd Msg )
init _ =
    ( { controlBar = ControlBar.init
      , sequencer = Sequencer.init
      , drumMachine = DrumMachine.init
      , activeChord = 0
      , playing = False
      , bpm = 200
      }
    , Cmd.none
    )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "root" ]
        [ div [ class "cardrows" ]
            [ div [ class "cardrow" ]
                [ Html.map ControlBarMsg (ControlBar.view model.controlBar)
                ]
            , div [ class "cardrow" ]
                [ Html.map SequencerMsg (Sequencer.view model.sequencer)
                , Html.map DrumMachineMsg (DrumMachine.view model.drumMachine)
                ]
            ]
        ]



-- UPDATE


type Msg
    = SetCurrentStep Int
    | ControlBarMsg ControlBar.Msg
    | SequencerMsg Sequencer.Msg
    | DrumMachineMsg DrumMachine.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetCurrentStep step ->
            let
                ( updatedDrumMachine, _ ) =
                    DrumMachine.update (DrumMachine.SetCurrentStep step) model.drumMachine

                ( updatedSequencer, _ ) =
                    Sequencer.update (Sequencer.SetCurrentStep step) model.sequencer
            in
            ( { model | activeChord = modBy 8 step, drumMachine = updatedDrumMachine, sequencer = updatedSequencer }, Cmd.none )

        ControlBarMsg controlBarMsg ->
            let
                ( subModel, subCmd ) =
                    ControlBar.update controlBarMsg model.controlBar
            in
            ( { model | controlBar = subModel }, Cmd.map ControlBarMsg subCmd )

        DrumMachineMsg drumMachineMsg ->
            let
                ( subModel, subCmd ) =
                    DrumMachine.update drumMachineMsg model.drumMachine
            in
            ( { model | drumMachine = subModel }, Cmd.map DrumMachineMsg subCmd )

        SequencerMsg sequencerMsg ->
            let
                ( subModel, subCmd ) =
                    Sequencer.update sequencerMsg model.sequencer
            in
            ( { model | sequencer = subModel }, Cmd.map SequencerMsg subCmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveCurrentStepUpdate
            SetCurrentStep
        , Sub.map ControlBarMsg ControlBar.subscriptions
        ]



-- PORTS


port receiveCurrentStepUpdate : (Int -> msg) -> Sub msg



-- MAIN


main =
    Browser.element { init = init, subscriptions = subscriptions, update = update, view = view }
