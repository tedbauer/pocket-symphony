port module Main exposing (..)

import Array exposing (Array)
import Browser
import Browser.Events exposing (onKeyDown)
import Debug exposing (toString)
import DrumMachine
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Json.Decode
import Keyboard.Event exposing (KeyboardEvent, decodeKeyboardEvent)
import Platform.Cmd as Cmd
import Sequencer
import String exposing (toInt)
import WebAudio exposing (oscillator)


port receiveCurrentChordUpdate : (Int -> msg) -> Sub msg


type alias Model =
    { sequencer : Sequencer.Model, drumMachine : DrumMachine.Model, activeChord : Int, playing : Bool, bpm : Int }


type Msg
    = SequencerMsg Sequencer.Msg
    | DrumMachineMsg DrumMachine.Msg
    | UpdateChord Int
    | ProcessKeyboardEvent KeyboardEvent


main =
    Browser.element { init = init, subscriptions = subscriptions, update = update, view = view }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveCurrentChordUpdate UpdateChord
        , onKeyDown (Json.Decode.map ProcessKeyboardEvent decodeKeyboardEvent)
        ]


port transmitBpm : Int -> Cmd msg


port sendAudioCommand : String -> Cmd msg


init : () -> ( Model, Cmd Msg )
init _ =
    ( { sequencer = Sequencer.initModel
      , drumMachine = DrumMachine.initModel
      , activeChord = 0
      , playing = False
      , bpm = 200
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DrumMachineMsg drumMachineMsg ->
            let
                ( subModel, subCmd ) =
                    DrumMachine.update drumMachineMsg model.drumMachine
            in
            ( { model | drumMachine = subModel }, Cmd.map (\subMsg -> DrumMachineMsg subMsg) subCmd )

        SequencerMsg Sequencer.Play ->
            ( { model | playing = True }, sendAudioCommand "play" )

        SequencerMsg Sequencer.Pause ->
            ( { model | playing = False }, sendAudioCommand "pause" )

        SequencerMsg Sequencer.Reset ->
            ( { model | playing = False, activeChord = 0 }, sendAudioCommand "reset" )

        SequencerMsg (Sequencer.UpdateBpm bpm) ->
            ( { model | bpm = bpm }, transmitBpm bpm )

        SequencerMsg sequencerMsg ->
            let
                ( subModel, subCmd ) =
                    Sequencer.update sequencerMsg model.sequencer
            in
            ( { model | sequencer = subModel }, Cmd.map (\subMsg -> SequencerMsg subMsg) subCmd )

        ProcessKeyboardEvent keyboardEvent ->
            processKeyboardEvent keyboardEvent model

        UpdateChord chordNumber ->
            let
                ( updatedDrumMachine, _ ) =
                    DrumMachine.update (DrumMachine.UpdateActiveColumn (modBy 16 chordNumber)) model.drumMachine
                ( updatedSequencer, _ ) =
                    Sequencer.update (Sequencer.UpdateActiveColumn (modBy 8 chordNumber)) model.sequencer
            in
            ( { model | activeChord = modBy 8 chordNumber, drumMachine = updatedDrumMachine, sequencer = updatedSequencer }, Cmd.none )


processKeyboardEvent : KeyboardEvent -> Model -> ( Model, Cmd Msg )
processKeyboardEvent event model =
    case event.key of
        Maybe.Just k ->
            if k == " " then
                if model.playing then
                    ( { model | playing = False }, sendAudioCommand "pause" )

                else
                    ( { model | playing = True }, sendAudioCommand "play" )

            else
                ( model, Cmd.none )

        Maybe.Nothing ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [ class "cardholder" ]
        [ Html.map (\msg -> SequencerMsg msg) (Sequencer.view model.sequencer)
        , Html.map (\msg -> DrumMachineMsg msg) (DrumMachine.view model.drumMachine)
        ]
