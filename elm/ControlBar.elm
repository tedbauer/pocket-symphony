module ControlBar exposing (..)

import Browser.Events exposing (onKeyDown)
import Debug exposing (toString)
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode
import Keyboard.Event exposing (KeyboardEvent, decodeKeyboardEvent)
import Knob
import SoundEngineController


type alias Model =
    { bpm : Knob.Model, playing : Bool, activeStep : Int }



-- MODEL


init : Model
init =
    { bpm = Knob.init 300 100 500 1
    , playing = False
    , activeStep = 0
    }



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "card" ]
        [ div
            [ class "controlbar" ]
            [ div [ class "playback-controls" ]
                [ div
                    [ class "play"
                    , onClick Play
                    , Html.Attributes.attribute "data-playing" (toString model.playing)
                    ]
                    [ text "▶️" ]
                , div
                    [ class "pause"
                    , onClick Pause
                    , Html.Attributes.attribute "data-playing" (toString model.playing)
                    ]
                    [ text "⏸️" ]
                ]
            , div
                [ class "tempocontrol" ]
                [ text "Tempo", Html.map BpmMessage (Knob.view 20 model.bpm) ]
            , div [ class "animals" ] [ text (animals model) ]
            , div [ class "maintitle" ] [ text "🎼 Pocket Symphony", div [ class "versionlabel" ] [ text "v1.0.0" ] ]
            ]
        ]


animals : Model -> String
animals model =
    if modBy 8 model.activeStep == 0 then
        "🦅\u{1FABF}🦏"

    else if modBy 4 model.activeStep == 0 then
        "\u{1FABF}🦏🦅"

    else
        "🦏🦅\u{1FABF}"



-- UPDATE


type Msg
    = BpmMessage Knob.Msg
    | Play
    | Pause
    | Reset
    | ProcessKeyboardEvent KeyboardEvent
    | SetCurrentStep Int


processKeyboardEvent : KeyboardEvent -> Model -> ( Model, Cmd Msg )
processKeyboardEvent event model =
    case event.key of
        Maybe.Just k ->
            if k == " " then
                if model.playing then
                    ( { model | playing = False }
                    , SoundEngineController.stepEngine (SoundEngineController.encode_audio_command_message "pause")
                    )

                else
                    ( { model | playing = True }
                    , SoundEngineController.stepEngine (SoundEngineController.encode_audio_command_message "play")
                    )

            else
                ( model, Cmd.none )

        Maybe.Nothing ->
            ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BpmMessage knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.bpm

                bpmCmd =
                    maybeValue
                        |> Maybe.map round
                        |> Maybe.map
                            (\bpm ->
                                Cmd.batch
                                    [ SoundEngineController.stepEngine (SoundEngineController.encode_bpm_message bpm)
                                    , SoundEngineController.stepEngine (SoundEngineController.encode_audio_command_message "pause")
                                    ]
                            )
                        |> Maybe.withDefault Cmd.none
            in
            ( { model | bpm = newKnob, playing = False }, bpmCmd )

        Play ->
            if not model.playing then
                ( { model | playing = True }
                , SoundEngineController.stepEngine (SoundEngineController.encode_audio_command_message "play")
                )

            else
                ( model, Cmd.none )

        Pause ->
            ( { model | playing = False }
            , SoundEngineController.stepEngine (SoundEngineController.encode_audio_command_message "pause")
            )

        Reset ->
            ( { model | activeStep = 0 }
            , SoundEngineController.stepEngine (SoundEngineController.encode_audio_command_message "reset")
            )

        ProcessKeyboardEvent event ->
            processKeyboardEvent event model

        SetCurrentStep step ->
            ( { model | activeStep = step }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ onKeyDown (Json.Decode.map ProcessKeyboardEvent decodeKeyboardEvent)
        , Sub.map BpmMessage
            (Knob.subscriptions model.bpm)
        ]
