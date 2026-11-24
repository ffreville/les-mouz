"""Génère les bruitages provisoires de Les Mouz (assets/sons/*.wav) par synthèse.

Sons doux et courts, pour rester dans le ton du jeu. Chacun peut être remplacé par
un vrai fichier portant le même nom : le jeu n'a rien à changer.
Usage : python3 tools/generer_sons.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sons")
random.seed(7)


def env(t, attack, decay):
    """Enveloppe : montée linéaire puis décroissance exponentielle."""
    if t < attack:
        return t / attack
    return math.exp(-(t - attack) / decay)


def bell(freq, t, decay=0.25):
    """Petite cloche : fondamentale + deux harmoniques plus courtes."""
    return (math.sin(2 * math.pi * freq * t)
            + 0.4 * math.sin(2 * math.pi * freq * 2.01 * t) * math.exp(-t / (decay / 2))
            + 0.15 * math.sin(2 * math.pi * freq * 3.02 * t) * math.exp(-t / (decay / 3))) * env(t, 0.004, decay)


class Noise:
    """Bruit filtré passe-bas (un pôle) : `smooth` proche de 1 = plus sourd."""

    def __init__(self, smooth):
        self.smooth = smooth
        self.value = 0.0

    def next(self):
        self.value = self.smooth * self.value + (1 - self.smooth) * random.uniform(-1, 1)
        return self.value


def render(name, duration, fn, gain=0.6):
    samples = [fn(i / RATE) for i in range(int(duration * RATE))]
    peak = max(1e-6, max(abs(s) for s in samples))
    fade = int(0.01 * RATE)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = bytearray()
        for i, s in enumerate(samples):
            if i > len(samples) - fade:
                s *= (len(samples) - i) / fade
            frames += struct.pack("<h", int(max(-1, min(1, s / peak * gain)) * 32767))
        w.writeframes(bytes(frames))


def notes(sequence, decay=0.25):
    """Suite de cloches : [(début en s, fréquence)]."""
    return lambda t: sum(bell(f, t - start, decay) for start, f in sequence if t >= start)


def main():
    os.makedirs(OUT, exist_ok=True)
    # Interface
    click = Noise(0.3)
    render("clic", 0.06, lambda t: (math.sin(2 * math.pi * 1800 * t) * 0.6 + click.next() * 0.4) * env(t, 0.001, 0.012), 0.35)
    render("achat", 0.5, notes([(0, 1318.5), (0.07, 1975.5)], 0.18), 0.45)
    render("vente", 0.5, notes([(0, 1975.5), (0.07, 1318.5)], 0.18), 0.4)
    render("sauvegarde", 0.7, notes([(0, 784), (0.09, 1046.5), (0.18, 1568)], 0.22), 0.4)
    render("alerte", 0.6, notes([(0, 880), (0.14, 659.3)], 0.2), 0.45)
    render("erreur", 0.25, lambda t: (math.sin(2 * math.pi * 196 * t) + 0.5 * math.sin(2 * math.pi * 233 * t)) * env(t, 0.005, 0.07), 0.4)
    # Construction : coup sourd (mur, sol) et pose d'objet (bois)
    thud = Noise(0.9)
    render("construire", 0.3, lambda t: (math.sin(2 * math.pi * (140 - 200 * t) * t) + thud.next() * 2.5) * env(t, 0.002, 0.06), 0.6)
    knock = Noise(0.6)
    render("poser", 0.2, lambda t: (math.sin(2 * math.pi * 420 * t) * 0.7 + math.sin(2 * math.pi * 690 * t) * 0.3 + knock.next() * 0.5) * env(t, 0.001, 0.035), 0.5)
    # Maison
    door = Noise(0.97)
    render("porte", 0.35, lambda t: (door.next() * 3 * env(t, 0.06, 0.08) + math.sin(2 * math.pi * 260 * t) * 0.5 * env(t - 0.02, 0.002, 0.03) * (t > 0.02)), 0.35)
    switch = Noise(0.2)
    render("interrupteur", 0.08, lambda t: (switch.next() * 0.6 + math.sin(2 * math.pi * 2600 * t) * 0.4) * env(t, 0.0005, 0.008), 0.35)
    water = Noise(0.55)
    render("eau", 1.6, lambda t: water.next() * (0.7 + 0.3 * math.sin(2 * math.pi * 7 * t)) * min(1, t / 0.15) * min(1, (1.6 - t) / 0.4), 0.3)
    flush = Noise(0.75)
    render("chasse", 1.4, lambda t: flush.next() * min(1, t / 0.05) * math.exp(-t / 0.6) * (0.8 + 0.2 * math.sin(2 * math.pi * 3 * t)), 0.4)
    sizzle = Noise(0.1)
    render("cuisson", 1.5, lambda t: sizzle.next() * (0.5 + 0.5 * (random.random() < 0.02)) * min(1, t / 0.2) * min(1, (1.5 - t) / 0.4), 0.22)
    render("micro_ondes", 0.5, lambda t: math.sin(2 * math.pi * 1568 * t) * (t < 0.12 or 0.2 < t < 0.32) * env(t % 0.2, 0.003, 0.2), 0.3)
    render("piano", 1.4, notes([(0, 523.3), (0.25, 659.3), (0.5, 784), (0.75, 1046.5)], 0.5), 0.4)
    crunch = Noise(0.4)
    render("manger", 0.6, lambda t: crunch.next() * sum(env(t - s, 0.003, 0.03) * (t >= s) for s in (0, 0.18, 0.36)), 0.35)


if __name__ == "__main__":
    main()
