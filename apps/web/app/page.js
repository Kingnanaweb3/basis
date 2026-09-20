import Reveal from "../components/Reveal";
import Backdrop from "../components/Backdrop";
import Nav from "../components/Nav";
import Hero from "../components/Hero";
import Problem from "../components/Problem";
import Steps from "../components/Steps";
import Affected from "../components/Affected";
import Token from "../components/Token";
import Footer from "../components/Footer";

export default function Page() {
  return (
    <>
      <Reveal />
      <Backdrop />
      <Nav />
      <Hero />
      <Problem />
      <Steps />
      <Affected />
      <Token />
      <Footer />
    </>
  );
}
