import { useState } from "react";
import { createRoot } from "react-dom/client";
import type { ReactNode } from "react";

type Person = { name: string; role: string; city: string; projects: number; followers: number };

function Avatar({ name }: { name: string }) {
  return (
    <div className="avatar" aria-hidden="true">
      {name[0]}
    </div>
  );
}

function Stat({ value, label }: { value: number; label: string }) {
  return (
    <span>
      <b>{value}</b>
      {label}
    </span>
  );
}

function ProfileCard({ person, children }: { person: Person; children: ReactNode }) {
  const [following, setFollowing] = useState(false);
  const followers = person.followers + (following ? 1 : 0);
  return (
    <article className="profile">
      <div className="cover" />
      <div className="body">
        <Avatar name={person.name} />
        <h2>{person.name}</h2>
        <p className="meta">
          {person.role} · {person.city}
        </p>
        {children}
        <div className="stats">
          <Stat value={person.projects} label="projects" />
          <Stat value={followers} label="followers" />
        </div>
        <button className={following ? "secondary" : ""} aria-pressed={following} onClick={() => setFollowing(!following)}>
          {following ? "Following" : "Follow"}
        </button>
      </div>
    </article>
  );
}

const sara: Person = { name: "Sara", role: "Frontend developer", city: "Alexandria", projects: 12, followers: 340 };

createRoot(document.getElementById("root")!).render(
  <ProfileCard person={sara}>
    <p>I build fast, accessible web apps with React and TypeScript.</p>
  </ProfileCard>,
);
