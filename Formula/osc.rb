class Osc < Formula
  include Language::Python::Virtualenv

  desc "The command-line interface to work with an Open Build Service"
  homepage "https://github.com/openSUSE/osc"
  url "https://github.com/openSUSE/osc/archive/0.163.0.tar.gz"
  sha256 "3d994350fe55f00c1819c669f11ab633b19df22a4bd55c3e5ef08364e600823d"
  head "https://github.com/openSUSE/osc.git"

  bottle do
    cellar :any
    sha256 "2fa943a2d22421c43b0207f3539bf2a67429a14c3863b41693d4fecd84ee42a0" => :high_sierra
    sha256 "154342969ef438ae7a1df6eff5a143671c1fce676671bb9fca23baa1296d1dc2" => :sierra
    sha256 "b1c225feb5c2a64f28499633f34c749189fee435232b7aa68b18bf623e136fa6" => :el_capitan
  end

  depends_on "swig" => :build
  depends_on "openssl" # For M2Crypto
  depends_on "python@2"

  resource "pycurl" do
    url "https://files.pythonhosted.org/packages/12/3f/557356b60d8e59a1cce62ffc07ecc03e4f8a202c86adae34d895826281fb/pycurl-7.43.0.tar.gz"
    sha256 "aa975c19b79b6aa6c0518c0cc2ae33528900478f0b500531dbcdbf05beec584c"
  end

  resource "urlgrabber" do
    url "https://files.pythonhosted.org/packages/29/1a/f509987826e17369c52a80a07b257cc0de3d7864a303175f2634c8bcb3e3/urlgrabber-3.10.2.tar.gz"
    sha256 "05b7164403d49b37fe00f7ac8401e56b00d0568ac45ee15d5f0610ac293c3070"
  end

  resource "M2Crypto" do
    url "https://files.pythonhosted.org/packages/01/bd/a41491718f9e2bebab015c42b5be7071c6695acfa301e3fc0480bfd6a15b/M2Crypto-0.27.0.tar.gz"
    sha256 "82317459d653322d6b37f122ce916dc91ddcd9d1b814847497ac796c4549dd68"
  end

  resource "typing" do
    url "https://files.pythonhosted.org/packages/ca/38/16ba8d542e609997fdcd0214628421c971f8c395084085354b11ff4ac9c3/typing-3.6.2.tar.gz"
    sha256 "d514bd84b284dd3e844f0305ac07511f097e325171f6cc4a20878d11ad771849"
  end

  def install
    # avoid pycurl error about compile-time and link-time curl version mismatch
    ENV.delete "SDKROOT"

    ENV["SWIG_FEATURES"]="-I#{Formula["openssl"].opt_include}"

    venv = virtualenv_create(libexec)
    venv.pip_install resources.reject { |r| r.name == "M2Crypto" || r.name == "pycurl" }

    resource("M2Crypto").stage do
      inreplace "setup.py" do |s|
        s.gsub! "self.openssl = '/usr'",
                "self.openssl = '#{Formula["openssl"].opt_prefix}'"
        s.gsub! "platform.system() == \"Linux\"",
                "platform.system() == \"Darwin\" or \\0"
      end
      venv.pip_install "."
    end

    # avoid error about libcurl link-time and compile-time ssl backend mismatch
    resource("pycurl").stage do
      system libexec/"bin/pip", "install",
             "--install-option=--libcurl-dll=/usr/lib/libcurl.dylib", "-v",
             "--no-binary", ":all:", "--ignore-installed", "."
    end

    inreplace "osc/conf.py", "'/etc/ssl/certs'", "'#{etc}/openssl/cert.pem'"
    venv.pip_install_and_link buildpath
    mv bin/"osc-wrapper.py", bin/"osc"
  end

  test do
    system bin/"osc", "--version"
  end
end
