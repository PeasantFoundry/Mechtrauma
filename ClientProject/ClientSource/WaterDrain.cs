/***
Water drain component
***/
using ModdingToolkit;

using System;
using Barotrauma;
using Barotrauma.Networking;
using Barotrauma.Particles;
using System.Reflection;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Barotrauma.Items.Components;
using System.Linq;

namespace Mechtrauma
{
    public partial class WaterDrain : Powered
    {
        private readonly List<(Vector2 position, ParticleEmitter emitter)> pumpOutEmitters = new List<(Vector2 position, ParticleEmitter emitter)>();
        private readonly List<(Vector2 position, ParticleEmitter emitter)> pumpInEmitters = new List<(Vector2 position, ParticleEmitter emitter)>();

        partial void InitProjSpecific(ContentXElement element)
        {
            foreach (var subElement in element.Elements())
            {
                switch (subElement.Name.ToString().ToLowerInvariant())
                {
                    case "pumpoutemitter":
                        pumpOutEmitters.Add((subElement.GetAttributeVector2("position", Vector2.Zero), new ParticleEmitter(subElement)));
                        break;
                    case "pumpinemitter":
                        pumpInEmitters.Add((subElement.GetAttributeVector2("position", Vector2.Zero), new ParticleEmitter(subElement)));
                        break;
                }
            }
        }

        partial void UpdateProjSpecific(float deltaTime)
        {
            if (FlowPercentage < -0.3f)
            {
                foreach (var (position, emitter) in pumpOutEmitters)
                {
                    if (item.CurrentHull != null && item.CurrentHull.Surface < item.Rect.Location.Y + position.Y) { continue; }

                    //only emit "pump out" particles when underwater
                    Vector2 relativeParticlePos = (item.WorldRect.Location.ToVector2() + position * item.Scale) - item.WorldPosition;
                    relativeParticlePos = MathUtils.RotatePoint(relativeParticlePos, item.FlippedX ? item.RotationRad : -item.RotationRad);
                    float angle = -item.RotationRad;
                    if (item.FlippedX)
                    {
                        relativeParticlePos.X = -relativeParticlePos.X;
                        angle += MathHelper.Pi;
                    }
                    if (item.FlippedY)
                    {
                        relativeParticlePos.Y = -relativeParticlePos.Y;
                    }

                    emitter.Emit(deltaTime, item.WorldPosition + relativeParticlePos, item.CurrentHull, angle,
                        velocityMultiplier: MathHelper.Lerp(0.5f, 1.0f, -FlowPercentage / 100.0f));
                }
            }
            else if (FlowPercentage > 0.3f)
            {
                foreach (var (position, emitter) in pumpInEmitters)
                {
                    Vector2 relativeParticlePos = (item.WorldRect.Location.ToVector2() + position * item.Scale) - item.WorldPosition;
                    relativeParticlePos = MathUtils.RotatePoint(relativeParticlePos, item.FlippedX ? item.RotationRad : -item.RotationRad);
                    float angle = -item.RotationRad;
                    if (item.FlippedX)
                    {
                        relativeParticlePos.X = -relativeParticlePos.X;
                        angle += MathHelper.Pi;
                    }
                    if (item.FlippedY)
                    {
                        relativeParticlePos.Y = -relativeParticlePos.Y;
                    }
                    emitter.Emit(deltaTime, item.WorldPosition + relativeParticlePos, item.CurrentHull, angle,
                        velocityMultiplier: MathHelper.Lerp(0.5f, 1.0f, FlowPercentage / 100.0f));
                }
            }
        }


    }
}