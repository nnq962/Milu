import SwiftUI

/// The picture by the user's name (user request 2026-11-12): the name's initial (the default) or
/// one of Milu's faces; no photo (user choice 2026-11-12). The choice follows the user to another
/// iPhone through iCloud (`CloudSettings`).
enum ProfileAvatar: Equatable {
    case initial
    case milu(MiluHero.Look)

    init(raw: String) {
        if raw.hasPrefix("milu:"), let look = MiluHero.Look(rawValue: String(raw.dropFirst(5))) {
            self = .milu(look)
        } else {
            // Anything else, a photo chosen in an earlier build among it: the initial.
            self = .initial
        }
    }

    var raw: String {
        switch self {
        case .initial: ""
        case .milu(let look): "milu:\(look.rawValue)"
        }
    }
}

/// The avatar drawn in a circle `size` wide: a Milu face, or the initial (a person glyph with no
/// name). `avatar` and `name` default to what is saved; the profile sheet passes what is being
/// chosen.
struct ProfileAvatarView: View {
    var avatar: ProfileAvatar? = nil
    var name: String? = nil
    let size: CGFloat

    @AppStorage(StorageKey.profileName) private var savedName = ""
    @AppStorage(StorageKey.profileAvatar) private var savedAvatar = ""

    var body: some View {
        ZStack {
            Circle().fill(Palette.primaryTint)
            switch avatar ?? ProfileAvatar(raw: savedAvatar) {
            case .milu(let look):
                // The face large in the circle, the slopes cut by its edge, the foot just below
                // it (the drawings are wide: whole, the face was small, Simulator 2026-11-12).
                Image(look.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 1.7)
                    .offset(y: size * 0.18)
            case .initial:
                if let initial = ProfileName.initial(of: name ?? savedName) {
                    Text(initial)
                        .font(Typography.fixedFont(size: size * 0.42, weight: .bold))
                        .foregroundStyle(Palette.primary)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.42))
                        .foregroundStyle(Palette.primary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}
