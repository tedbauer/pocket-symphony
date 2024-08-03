port module Envelope exposing (..)

import Html exposing (Html, div, li, text, tr, track, ul)
import Html.Attributes exposing (class, height, width)
import Html.Events exposing (onClick, onMouseDown)
import Knob
import Svg exposing (line, svg)


type alias Model =
    { attack : Knob.Model
    , sustain : Knob.Model
    , decay : Knob.Model
    , release : Knob.Model
    }



-- MODEL


init : Model
init =
    { attack = Knob.init 0 0 0.19 0.01
    , sustain = Knob.init 0 0 1 0.01
    , decay = Knob.init 0 0 0.19 0.01
    , release = Knob.init 0 0 0.19 0.01
    }



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "card" ]
        [ div [ class "cardtitle" ] [ text "✉️ Envelope" ]
        , div [ class "envelope" ]
            [ div [ class "envelopecontrol" ]
                [ envelopeControl "Attack" model.attack AttackMsg
                , envelopeControl "Sustain" model.sustain SustainMsg
                , envelopeControl "Decay" model.decay DecayMsg
                , envelopeControl "Release" model.release ReleaseMsg
                ]
            ]
        ]


envelopeControl : String -> Knob.Model -> (Knob.Msg -> Msg) -> Html Msg
envelopeControl label knobModel msg =
    div [ class "envelopecontrol" ]
        [ text label
        , Html.map msg (Knob.view knobModel)
        ]



-- UPDATE


type Msg
    = AttackMsg Knob.Msg
    | SustainMsg Knob.Msg
    | DecayMsg Knob.Msg
    | ReleaseMsg Knob.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AttackMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.attack
            in
            ( { model | attack = newKnob }
            , maybeValue |> Maybe.map transmitAttack |> Maybe.withDefault Cmd.none
            )

        SustainMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.sustain
            in
            ( { model | sustain = newKnob }
            , maybeValue |> Maybe.map transmitSustain |> Maybe.withDefault Cmd.none
            )

        DecayMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.decay
            in
            ( { model | decay = newKnob }
            , maybeValue |> Maybe.map transmitDecay |> Maybe.withDefault Cmd.none
            )

        ReleaseMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.release
            in
            ( { model | release = newKnob }
            , maybeValue |> Maybe.map transmitRelease |> Maybe.withDefault Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map AttackMsg
            (Knob.subscriptions model.attack)
        , Sub.map
            SustainMsg
            (Knob.subscriptions model.sustain)
        , Sub.map DecayMsg (Knob.subscriptions model.decay)
        , Sub.map ReleaseMsg (Knob.subscriptions model.release)
        ]



-- PORTS


port transmitAttack : Float -> Cmd msg


port transmitSustain : Float -> Cmd msg


port transmitDecay : Float -> Cmd msg


port transmitRelease : Float -> Cmd msg
