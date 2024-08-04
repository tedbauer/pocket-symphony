port module Envelope exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, height, style, width)
import Knob
import Svg exposing (path, svg)
import Svg.Attributes


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
            [ graph model.attack.value model.decay.value model.sustain.value model.release.value
            , div [ class "envelopecontrol" ]
                [ div [ class "envelopeknob" ]
                    [ Html.map AttackMsg (Knob.view 30 model.attack)
                    , text "Attack"
                    ]
                , div [ class "envelopeknob" ] [ Html.map DecayMsg (Knob.view 30 model.decay), text "Decay" ]
                , div [ class "envelopeknob" ] [ Html.map SustainMsg (Knob.view 30 model.sustain), text "Sustain" ]
                , div [ class "envelopeknob" ] [ Html.map ReleaseMsg (Knob.view 30 model.release), text "Release" ]
                ]
            ]
        ]


graph : Float -> Float -> Float -> Float -> Html Msg
graph attack decay sustain release =
    div [ class "graph" ]
        [ svg
            [ width 150
            , height 100
            , Svg.Attributes.viewBox "0 0 400 200"
            ]
            [ Svg.polyline
                [ Svg.Attributes.points (generateWavePoints attack decay sustain release)
                , Svg.Attributes.fill "none"
                , Svg.Attributes.stroke "purple"
                , Svg.Attributes.strokeWidth "2"
                ]
                []
            ]
        ]


generateWavePoints : Float -> Float -> Float -> Float -> String
generateWavePoints attack decay sustain release =
    let
        width =
            400

        maxValue =
            150

        attackEnd =
            attack * width

        decayEnd =
            attackEnd + decay * width

        sustainEnd =
            decayEnd + ((1 - sustain) * width)

        releaseEnd =
            sustainEnd + release * width
    in
    String.join " "
        [ String.fromFloat 0 ++ "," ++ String.fromFloat maxValue
        , String.fromFloat attackEnd ++ "," ++ String.fromFloat maxValue
        , String.fromFloat decayEnd ++ "," ++ String.fromFloat (sustain * maxValue)
        , String.fromFloat sustainEnd ++ "," ++ String.fromFloat (sustain * maxValue)
        , String.fromFloat releaseEnd ++ "," ++ String.fromFloat 0
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
