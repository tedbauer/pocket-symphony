port module ControlBar exposing (..)

import Debug exposing (toString)
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import String exposing (toInt)
import Keyboard.Event exposing (KeyboardEvent, decodeKeyboardEvent)
import Browser.Events exposing (onKeyDown)
import Json.Decode


type alias Model =
    { bpm : Int, playing : Bool, activeStep : Int }



-- MODEL


init : Model
init =
    { bpm = 200
    , playing = False
    , activeStep = 0
    }



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "card" ]
        [ div [ class "play", onClick Play ] [ text "▶️" ]
        , div [ class "pause", onClick Pause ] [ text "⏸️" ]
        , div [ class "reset", onClick Reset ] [ text "⏮️" ]
        , input
            [ class "bpm"
            , type_ "text"
            , placeholder (toString model.bpm)
            , value (toString model.bpm)
            , onInput
                (\bpm ->
                    case toInt bpm of
                        Maybe.Just v ->
                            UpdateBpm v

                        Maybe.Nothing ->
                            UpdateBpm model.bpm
                )
            ]
            [ text "ho" ]
        ]



-- UPDATE


type Msg
    = UpdateBpm Int
    | Play
    | Pause
    | Reset
    | ProcessKeyboardEvent KeyboardEvent


processKeyboardEvent : KeyboardEvent -> Model -> ( Model, Cmd Msg )
processKeyboardEvent event model =
    case event.key of
        Maybe.Just k ->
            if k == " " then
                if model.playing then
                    ( { model | playing = False }, sendAudioCommand "pause")

                else
                    ( { model | playing = True }, sendAudioCommand "play")

            else
                ( model, Cmd.none )

        Maybe.Nothing ->
            ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateBpm v ->
            ( { model | bpm = v }, transmitBpm v )

        Play ->
            ( { model | playing = True }, sendAudioCommand "play" )

        Pause ->
            ( { model | playing = False }, sendAudioCommand "pause" )

        Reset ->
            ( { model | activeStep = 0 }, sendAudioCommand "reset" )

        ProcessKeyboardEvent event ->
            processKeyboardEvent event model


-- SUBSCRIPTIONS

subscriptions : Sub Msg
subscriptions =
    Sub.batch [
        onKeyDown (Json.Decode.map ProcessKeyboardEvent decodeKeyboardEvent)
    ]


-- PORTS


port sendAudioCommand : String -> Cmd msg


port transmitBpm : Int -> Cmd msg
