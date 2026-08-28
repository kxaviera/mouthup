import React, { createContext, useContext, useState, ReactNode } from 'react';
import { MoodId } from '../constants/moods';

interface AppState {
  nickname: string;
  city: string;
  onboardingDone: boolean;
  selectedMood: MoodId | null;
  pollVote: number | null;
  setNickname: (name: string) => void;
  setCity: (city: string) => void;
  completeOnboarding: () => void;
  setSelectedMood: (mood: MoodId) => void;
  setPollVote: (vote: number) => void;
}

const AppContext = createContext<AppState | null>(null);

export function AppProvider({ children }: { children: ReactNode }) {
  const [nickname, setNickname] = useState('CoolBreeze47');
  const [city, setCity] = useState('Delhi');
  const [onboardingDone, setOnboardingDone] = useState(false);
  const [selectedMood, setSelectedMood] = useState<MoodId | null>(null);
  const [pollVote, setPollVote] = useState<number | null>(null);

  return (
    <AppContext.Provider
      value={{
        nickname,
        city,
        onboardingDone,
        selectedMood,
        pollVote,
        setNickname,
        setCity,
        completeOnboarding: () => setOnboardingDone(true),
        setSelectedMood,
        setPollVote,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used within AppProvider');
  return ctx;
}
