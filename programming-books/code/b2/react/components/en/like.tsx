import { useState } from "react";
import { createRoot } from "react-dom/client";

function LikeButton({ initial }: { initial: number }) {
  const [likes, setLikes] = useState(initial);
  const [liked, setLiked] = useState(false);

  function toggle() {
    setLiked(!liked);
    setLikes(liked ? likes - 1 : likes + 1);
  }

  return (
    <button className={liked ? "" : "secondary"} aria-pressed={liked} onClick={toggle}>
      {liked ? "♥ Liked" : "♡ Like"} · {likes} likes
    </button>
  );
}

createRoot(document.getElementById("root")!).render(
  <p style={{ display: "flex", gap: 8 }}>
    <LikeButton initial={41} />
    <LikeButton initial={7} />
  </p>,
);
