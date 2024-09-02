module Delay exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Knob



-- MODEL


type alias Model =
    { time : Knob.Model
    , feedback : Knob.Model
    , mix : Knob.Model
    }


init : Model
init =
    { time = Knob.init 0 100 50 50
    , feedback = Knob.init 0 100 30 30
    , mix = Knob.init 0 100 20 20
    }



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "card" ]
        [ div [ class "cardtitle" ] [ text "🔁 Delay" ]
        , div [ class "delay" ]
            [ div [ class "delayparams" ]
                [ div [ class "labeledknob" ] [ Html.map TimeMsg (Knob.view 30 model.time), text "Time" ]
                , div [ class "labeledknob" ] [ Html.map FeedbackMsg (Knob.view 30 model.feedback), text "Feedback" ]
                , div [ class "labeledknob" ] [ Html.map MixMsg (Knob.view 30 model.mix), text "Mix" ]
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
            in
            ( { model | time = newKnob }, Cmd.none )

        FeedbackMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.feedback
            in
            ( { model | feedback = newKnob }, Cmd.none )

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
