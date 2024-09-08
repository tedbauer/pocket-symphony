module Delay exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Knob
import SoundEngineController



-- MODEL


type alias Model =
    { time : Knob.Model
    , feedback : Knob.Model
    , mix : Knob.Model
    }


init : Model
init =
    { time = Knob.init 0.9 0.05 1 0.01
    , feedback = Knob.init 0 0 0.9 0.01
    , mix = Knob.init 0 100 20 20
    }



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "card" ]
        [ div [ class "cardtitle" ] [ text "🔁 Delay" ]
        , div [ class "delay" ]
            [ div [ class "delayparams" ]
                [ div [ class "labeledknob-horizontal-thin" ] [ Html.map TimeMsg (Knob.view 30 model.time), text "Time" ]
                , div [ class "labeledknob-horizontal-thin" ] [ Html.map FeedbackMsg (Knob.view 30 model.feedback), text "Feedback" ]
                ]
            ]
        ]



-- UPDATE


type Msg
    = TimeMsg Knob.Msg
    | FeedbackMsg Knob.Msg
    | MixMsg Knob.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TimeMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.time

                newModel =
                    { model | time = newKnob }

                cmd =
                    case maybeValue of
                        Just value ->
                            SoundEngineController.stepEngine (SoundEngineController.encode_delay "time" value)

                        Nothing ->
                            Cmd.none
            in
            ( newModel, cmd )

        FeedbackMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.feedback

                cmd =
                    case maybeValue of
                        Just value ->
                            SoundEngineController.stepEngine (SoundEngineController.encode_delay "feedback" value)

                        Nothing ->
                            Cmd.none
            in
            ( { model | feedback = newKnob }, cmd )

        MixMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.mix
            in
            ( { model | mix = newKnob }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map TimeMsg (Knob.subscriptions model.time)
        , Sub.map FeedbackMsg (Knob.subscriptions model.feedback)
        , Sub.map MixMsg (Knob.subscriptions model.mix)
        ]
