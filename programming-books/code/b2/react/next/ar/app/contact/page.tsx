import type { Metadata } from "next";
import { ContactForm } from "./ContactForm";

export const metadata: Metadata = { title: "تواصل معنا" };

export default function ContactPage() {
  return (
    <section className="card">
      <h1>تواصل معنا</h1>
      <ContactForm />
    </section>
  );
}
