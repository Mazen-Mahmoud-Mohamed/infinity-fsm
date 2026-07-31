import { body } from 'express-validator';

export const updateOrganizationSettingsValidator = [
  body('name').optional().isString().trim().notEmpty().isLength({ max: 200 }),
  body('contactEmail').optional({ nullable: true }).isEmail().normalizeEmail(),
  body('contactPhone')
    .optional({ nullable: true })
    .isString()
    .trim()
    .isLength({ max: 40 }),
  body('timezone').optional().isString().trim().isLength({ max: 80 }),
  body('address').optional({ nullable: true }).isObject(),
  body('address.line1').optional({ nullable: true }).isString().trim().isLength({ max: 200 }),
  body('address.line2').optional({ nullable: true }).isString().trim().isLength({ max: 200 }),
  body('address.city').optional({ nullable: true }).isString().trim().isLength({ max: 120 }),
  body('address.governorate')
    .optional({ nullable: true })
    .isString()
    .trim()
    .isLength({ max: 120 }),
  body('address.country').optional({ nullable: true }).isString().trim().isLength({ max: 120 }),
  body('address.postalCode')
    .optional({ nullable: true })
    .isString()
    .trim()
    .isLength({ max: 40 }),
  body('workingHours').optional().isObject(),
  body('workingHours.start')
    .optional()
    .matches(/^([01]\d|2[0-3]):[0-5]\d$/)
    .withMessage('workingHours.start must be HH:mm'),
  body('workingHours.end')
    .optional()
    .matches(/^([01]\d|2[0-3]):[0-5]\d$/)
    .withMessage('workingHours.end must be HH:mm'),
  body('workingHours.timezone').optional().isString().trim().isLength({ max: 80 }),
];
