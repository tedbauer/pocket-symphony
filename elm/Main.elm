port module Main exposing (..)

import Browser
import ControlBar
import DrumMachine
import Envelope
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onMouseDown)
import Lfo
import Platform.Cmd as Cmd
import Sequencer


type alias Model =
    { controlBar : ControlBar.Model, sequencer : Sequencer.Model, drumMachine : DrumMachine.Model, lfo : Lfo.Model, envelope : Envelope.Model }



-- MODEL


init : () -> ( Model, Cmd Msg )
init _ =
    ( { controlBar = ControlBar.init
      , sequencer = Sequencer.init
      , drumMachine = DrumMachine.init
      , lfo = Lfo.init
      , envelope = Envelope.init
      }
    , Cmd.none
    )



-- VIEW


generateWavePoints : Int -> Float -> Float -> String
generateWavePoints width amplitude frequency =
    List.range 0 width
        |> List.map
            (\x ->
                let
                    y =
                        amplitude * sin (frequency * toFloat x * pi / 180)
                in
                String.fromInt x ++ "," ++ String.fromFloat (100 - y)
            )
        |> String.join " "


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
            , div [ class "cardrow" ]
                [ Html.map LfoMsg (Lfo.view model.lfo)
                , div [ class "card" ]
                    [ div
                        [ class "cardtitle" ]
                        [ text "🔊 Delay" ]
                    ]
                , Html.map EnvelopeMsg (Envelope.view model.envelope)
                ]
            ]
        ]



-- UPDATE


type Msg
    = SetCurrentStep Int
    | ControlBarMsg ControlBar.Msg
    | SequencerMsg Sequencer.Msg
    | DrumMachineMsg DrumMachine.Msg
    | EnvelopeMsg Envelope.Msg
    | LfoMsg Lfo.Msg


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
            ( { model | drumMachine = updatedDrumMachine, sequencer = updatedSequencer }, Cmd.none )

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

        LfoMsg lfoMsg ->
            let
                ( subModel, subCmd ) =
                    Lfo.update lfoMsg model.lfo
            in
            ( { model | lfo = subModel }, Cmd.map LfoMsg subCmd )

        EnvelopeMsg envelopeMsg ->
            let
                ( subModel, subCmd ) =
                    Envelope.update envelopeMsg model.envelope
            in
            ( { model | envelope = subModel }, Cmd.map EnvelopeMsg subCmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receiveCurrentStepUpdate
            SetCurrentStep
        , Sub.map ControlBarMsg ControlBar.subscriptions
        , Sub.map EnvelopeMsg (Envelope.subscriptions model.envelope)
        , Sub.map LfoMsg (Lfo.subscriptions model.lfo)
        ]



-- PORTS


port receiveCurrentStepUpdate : (Int -> msg) -> Sub msg



-- MAIN


main =
    Browser.element { init = init, subscriptions = subscriptions, update = update, view = view }
